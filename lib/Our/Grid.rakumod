unit class Our::Grid:api<1>:auth<Mark Devine (mark@markdevine.com)>;

use Data::Dump::Tree;
use Base64::Native;
use Color::Names:api<2>;
use Cro::HTTP::Client;
use JSON::Fast;
use JSON::Marshal;
use JSON::Unmarshal;
use Our::Cache;
use Our::Grid::Cell;
use Our::Grid::Cell::Fragment;
use Our::Utilities;
use Our::Redis;
use Text::CSV;
use Terminal::UI 'ui';
use GTK::Simple;
use GTK::Simple::App;
use GTK::Simple::Frame;
use GTK::Simple::TextView;
use GTK::Simple::VBox;

enum OUTPUTS (
    csv             => 'Text::CSV',
    html            => '1',
    json            => 'JSON::Fast',
    tui             => 'Terminal::UI',
#   xlsl            => 'Spreadsheet::XLSX',
    xml             => 'LibXML',
);

my class Body {
    has @.cells;
    has @.headings;
    has %.meta;
    has $.title                         is rw       = $*PROGRAM.Str;
}

has                 $.term-size;
has Body            $!body;
has Int             $.current-row       is rw       = 0;
has Int             $.current-col       is rw       = 0;

has         $!title             is built    = '';
has Bool    $!reverse-highlight is built    = False;

submethod TWEAK {
    $!term-size         = term-size;                                            # $!term-size.rows $!term-size.cols
    $!body             .= new;
    self.title($!title) if $!title;
    self.reverse-highlight($!reverse-highlight);
}

method reverse-highlight (Bool $reverse-highlight?) {
    $!body.meta<reverse-highlight>         = $reverse-highlight with $reverse-highlight;
    return $!body.meta<reverse-highlight>;
}

method title (Str $title?) {
    $!body.title   = $title with $title;
    return $!body.title;
}

method receive-proxy-mail-via-redis (Str:D :$redis-key!) {
    my $redis           = Our::Redis.new;
    $!body              = unmarshal($redis.GET(:key($redis-key)), Body);
    loop (my $heading = 0; $heading < $!body.headings.elems; $heading++) {
        loop (my $fragment = 0; $fragment < $!body.headings[$heading]<fragments>.elems; $fragment++) {
            $!body.headings[$heading]<fragments>[$fragment] = unmarshal($!body.headings[$heading]<fragments>[$fragment], Our::Grid::Cell::Fragment);
        }
    }
    loop ($heading = 0; $heading < $!body.headings.elems; $heading++) {
         $!body.headings[$heading] = unmarshal($!body.headings[$heading], Our::Grid::Cell);
    }
    loop (my $row = 0; $row < $!body.cells.elems; $row++) {
        loop (my $col = 0; $col < $!body.cells[$row].elems; $col++) {
            loop (my $fragment = 0; $fragment < $!body.cells[$row][$col]<fragments>.elems; $fragment++) {
                $!body.cells[$row][$col]<fragments>[$fragment] = unmarshal($!body.cells[$row][$col]<fragments>[$fragment], Our::Grid::Cell::Fragment);
            }
        }
    }
    loop ($row = 0; $row < $!body.cells.elems; $row++) {
        loop (my $col = 0; $col < $!body.cells[$row].elems; $col++) {
            $!body.cells[$row][$col] = unmarshal($!body.cells[$row][$col], Our::Grid::Cell);
        }
    }
#   get-html -> SMTP
}

method send-proxy-mail-via-redis (Str:D :$cro-host = '127.0.0.1', Int:D :$cro-port = 22151) {
    my $redis-key       = base64-encode($*PROGRAM ~ '_' ~ sprintf("%09d", $*PID) ~ '_' ~ DateTime.now.posix(:real)).decode.encode.Str;
    self.redis-set($redis-key);
# add options like From:, To:, Cc:, Bcc:, Subj:
    my $Cro-URL         = 'http://'
                        ~ $cro-host
                        ~ ':'
                        ~ $cro-port
                        ~ '/proxy-mail-via-redis'
                        ~ '/' ~ $redis-key
                        ;
#put $Cro-URL;
    my $response        = await Cro::HTTP::Client.get($Cro-URL);
    my $body            = await $response.body;
#say $body;
}

method redis-set (Str:D $redis-key!) {
    my $redis   = Our::Redis.new;
    my $status  = $redis.SET(:key($redis-key), :value(marshal($!body)));
    die 'Redis SET failed with status <' ~ $status ~ '>' if $status;
    $redis.EXPIRE(:key($redis-key), :60seconds) or die 'Redis EXPIRE failed!';
}

multi method add-heading (Str:D $text!, *%opts) {
    self.add-heading(:cell(Our::Grid::Cell.new(:$text, |%opts)));
}

multi method add-heading (Our::Grid::Cell:D :$cell, *%opts) {
    my $column                      = $!body.headings.elems;
    $!body.headings.append:         $cell;
    $!body.meta<col-width>[$column] = 0                     without $!body.meta<col-width>[$column];
    $!body.meta<col-width>[$column] = $cell.TEXT.Str.chars  if $cell.TEXT.Str.chars > $!body.meta<col-width>[$column];
}

multi method add-cell (Str:D $text!, *%opts) {
    self.add-cell(:cell(Our::Grid::Cell.new(:$text, |%opts)));
}

multi method add-cell (Our::Grid::Cell:D :$cell, :$row, :$col) {
    with $row {
        given $row {
            when Bool   { ++$!current-row if $!body.cells.elems > 0;          }
            when Int    { $!current-row = $row;                         }
            }
    }
    if $!body.cells[$!current-row]:!exists {
        $!body.cells[$!current-row]   = Array.new();
        $!current-col           = 0;
    }
    with $col {
        given $col {
            when Bool   { ++$!current-col                               }
            when Int    { $!current-col = $col;                         }
            default     { $!current-col = $!body.cells[$!current-row].elems;  }
        }
    }
#   sort inferences

    unless $!body.meta<column-sort-types>[$!current-col]:exists && $!body.meta<column-sort-types>[$!current-col] ~~ 'string' {
        my $proposed-sort-type;
        given $cell.cell-sort-type {
            when 'digits'       { $proposed-sort-type   = 'digits';     }
            when 'name-number'  {
                $!body.meta<column-sort-device-max>[$!current-col] = 0 without $!body.meta<column-sort-device-max>[$!current-col];
                if $!body.meta<column-sort-device-names>[$!current-col] {
                    if $!body.meta<column-sort-device-names>[$!current-col] ne $cell.cell-sort-device-name {
                        $proposed-sort-type     = 'string';
                    }
                    else {
                        $proposed-sort-type     = 'name-number';
                        $!body.meta<column-sort-device-max>[$!current-col] = $cell.cell-sort-device-number if $cell.cell-sort-device-number > $!body.meta<column-sort-device-max>[$!current-col];
                    }
                }
                else {
                    $proposed-sort-type         = 'name-number';
                    $!body.meta<column-sort-device-names>[$!current-col] = $cell.cell-sort-device-name;
                    $!body.meta<column-sort-device-max>[$!current-col] = $cell.cell-sort-device-number if $cell.cell-sort-device-number > $!body.meta<column-sort-device-max>[$!current-col];
                }
            }
            default             { $proposed-sort-type = 'string';       }
        }
        $!body.meta<column-sort-types>[$!current-col]  = $proposed-sort-type   without $!body.meta<column-sort-types>[$!current-col];
        $!body.meta<column-sort-types>[$!current-col]  = 'string'              if $proposed-sort-type !~~ $!body.meta<column-sort-types>[$!current-col];
    }
#   width accumulators
    $!body.meta<col-width>[$!current-col]          = 0                     without $!body.meta<col-width>[$!current-col];
    $!body.meta<col-raw-text-width>[$!current-col] = 0                     without $!body.meta<col-raw-text-width>[$!current-col];
    $!body.meta<col-width>[$!current-col]          = $cell.TEXT.Str.chars  if $cell.TEXT.Str.chars > $!body.meta<col-width>[$!current-col];
    $!body.meta<col-raw-text-width>[$!current-col] = $cell.text.Str.chars  if $cell.text.Str.chars > $!body.meta<col-raw-text-width>[$!current-col];
    if $!current-col > $!body.cells[$!current-row].elems {
        loop (my $i = $col; $i >= 0; $i--) {
            $!body.meta<col-width>[$i]             = 0                 without $!body.meta<col-width>[$i];
            $!body.meta<col-raw-text-width>[$i]    = 0                 without $!body.meta<col-raw-text-width>[$i];
        }
    }
    $!body.cells[$!current-row][$!current-col++] = $cell;
}

multi method sort-by-columns (:@sort-columns!, :$descending) {
    return False unless self!grid-check;
    my $row-digits          = $!body.cells.elems;
    $row-digits             = "$row-digits".chars;
    my %sortable-rows;
    my $sort-string;
    loop (my $row = 0; $row < $!body.cells.elems; $row++) {
        $sort-string        = '';
        for @sort-columns -> $col {
            die '$col (' ~ $col ~ ') out of range for grid! (0 <= col <= ' ~ $!body.meta<col-width>.elems - 1 ~ ')' unless 0 <= $col < $!body.meta<col-width>.elems;
            given $!body.meta<column-sort-types>[$col] {
                when 'string'       { $sort-string ~= $!body.cells[$row][$col].text.chars ?? $!body.cells[$row][$col].text ~ '_' !! ' _';                                                               }
                when 'digits'       { $sort-string ~= sprintf('%0' ~ $!body.meta<col-raw-text-width>[$col] ~ 'd', $!body.cells[$row][$col].text.chars ?? $!body.cells[$row][$col].text !! "0") ~ '_';   }
                when 'name-number'  { $sort-string ~= $!body.cells[$row][$col].text.chars ?? sprintf('%0' ~  "$!body.meta<column-sort-device-max>[$col]".chars ~ 'd',
                                                        $!body.cells[$row][$col].text.substr($!body.meta<column-sort-device-names>[$col].chars).Int) ~ '_' !! ' _';                                     }
            }
        }
        $sort-string       ~= sprintf("%0" ~ $row-digits ~ "d", $row);
        %sortable-rows{$sort-string} = $row;
    }
    $!body.meta<sort-order>    = Array.new;

### The below incantation sorts name_number & string & digit all together, magically.
### Since we need to sort by multiple columns (normalizing data by their peculiarity),
### I'll stick with the current ham-handed implementation for now.  Maybe I'll see a
### way to benefit from this magic spell and change it at some future date.
###
###     sort(*.split(/\d+/, :kv).map({ (try .Numeric) // $_}).List)

    for %sortable-rows.keys.sort -> $key {
        $!body.meta<sort-order>.push: %sortable-rows{$key};
    }
    $!body.meta<sort-order>    = $!body.meta<sort-order>.reverse.Array if $descending;
}

method !sort-order-check {
    return True                 if $!body.meta<sort-order> ~~ Array && $!body.meta<sort-order>.elems;
    $!body.meta<sort-order>    = Array.new;
    loop (my $s = 0; $s < $!body.cells.elems; $s++) {
        $!body.meta<sort-order>.push: $s;
    }
}

method !grid-check {
    return False if $!body.headings.elems && $!body.headings.elems != $!body.cells[0].elems;
#   die '$!body.headings.elems <' ~ $!body.headings.elems ~ '> != <' ~ $!body.cells[0].elems ~ '> $!body.cells[0].elems' if $!body.headings.elems && $!body.headings.elems != $!body.cells[0].elems;
    self!sort-order-check;
    return True;
}

method !datafy {
    self!sort-order-check;
    my @data    = Array.new();
    for $!body.headings.list -> $heading {
        @data[0].push: $heading.TEXT;
    }
    for $!body.meta<sort-order>.list -> $row {
        loop (my $col = 0; $col < $!body.cells[$row].elems; $col++) {
            given $!body.cells[$row][$col] {
                when Our::Grid::Cell:D  { @data[$row + 1].push: $!body.cells[$row][$col].TEXT;    }
                default                 { @data[$row + 1].push: '';                         }
            }
        }
    }
    @data;
}

method csv-print {
    return False unless self!grid-check;
    csv(in => csv(in => self!datafy), out => $*OUT);
}

method json-print {
    return False unless self!grid-check;
    put to-json(self!datafy);
}

method html-print {
    return False unless self!grid-check;
    print q:to/ENDOFHTMLHEAD/;
    <!DOCTYPE html>
    <html>
        <head>
            <style>
                table, h1, th, td {
                    margin-left: auto; 
                    margin-right: auto;
                    padding: 5px;
                    text-align: center;
                }
                th, td {
                    border-bottom: 1px solid #ddd;
                }
                tr:hover {background-color: coral; }
                body {
                    color: #222;
                    background: #fff;
                    font: 100% system-ui;
                }
                a {
                    color: #0033cc;
                }
                @media (prefers-color-scheme: dark) {
                    body {
                        color: #eee;
                        background: #121212;
                    }
                    body a {
                        color: #809fff;
                    }
                }
            </style>
        </head>
    ENDOFHTMLHEAD
    put ' ' x 4 ~ '<body>';
    put ' ' x 8 ~ '<h1>' ~ self.title ~ '</h1>' if self.title;
    put ' ' x 8 ~ '<table>';
    put ' ' x 12 ~ '<tr>';
    for $!body.headings.list -> $heading {
        put ' ' x 16 ~ '<th>' ~ self!subst-ml-text($heading.TEXT) ~ '</th>';
    }
    put ' ' x 12 ~ '</tr>';
    for $!body.meta<sort-order>.list -> $row {
        put ' ' x 12 ~ '<tr>';
        loop (my $col = 0; $col < $!body.cells[$row].elems; $col++) {
            print ' ' x 16 ~ '<td style="';
            if $!body.cells[$row][$col] ~~ Our::Grid::Cell:D {
                given $!body.cells[$row][$col] {
                    if .justification {
                        when 'left'     { print 'text-align: left;';    }
                        when 'center'   { print 'text-align: center;';  }
                        when 'right'    { print 'text-align: right;';   }
                    }
                    loop (my $f = 0; $f < .fragments.elems; $f++) {
                        if .fragments[$f].foreground {
                            print ' color:'     ~ .fragments[$f].foreground ~ ';';
                            last;
                        }
                    }
                    my $background = '';
                    loop ($f = 0; $f < .fragments.elems; $f++) {
                        if .fragments[$f].background {
                            $background = .fragments[$f].background;
                            print ' background-color:' ~ $background   ~ ';';
                            last;
                        }
                    }
                    print ' background-color:'  ~ .highlight    ~ ';'   if !$background && .highlight;
                    print '"';
                }
                print '>' ~ self!subst-ml-text($!body.cells[$row][$col].TEXT);
            }
            else {
                print '">';
            }
            put '</td>';
        }
        put ' ' x 12 ~ '</tr>';
    }
    put ' ' x 8 ~ '</table>';
    put ' ' x 4 ~ '</body>';
    put '</html>';
}

method !subst-ml-text (Str:D $s) {
    my $result  = $s;
    $result     = $result.subst('<', '&lt;',    :g);
    $result     = $result.subst('>', '&gt;',    :g);
    $result     = $result.subst('&', '&amp;',   :g);
    $result     = $result.subst("'", '&apos;',  :g);
    $result     = $result.subst('"', '&quot;',  :g);
    return $result;
}

method xml-print {
    die 'Cannot generate XML without column $!body.headings' unless $!body.headings.elems;
    die '$!body.headings.elems <' ~ $!body.headings.elems ~ '> != <' ~ $!body.cells[0].elems ~ '> $!body.cells[0].elems' unless $!body.headings.elems == $!body.cells[0].elems;
    self!sort-order-check;
    put '<?xml version="1.0" encoding="UTF-8"?>';
    put '<root>';
    my @headers;
    loop (my $i = 0; $i < $!body.headings.elems; $i++) {
        @headers[$i] = $!body.headings[$i].TEXT;
        @headers[$i] = @headers[$i].subst: ' ', '';
        @headers[$i] = @headers[$i].subst: '%', 'PCT';
    }
    for $!body.meta<sort-order>.list -> $row {
        put ' ' x 4 ~ '<row' ~ $row ~ '>';
        loop (my $col = 0; $col < $!body.cells[$row].elems; $col++) {
            if $!body.cells[$row][$col] ~~ Our::Grid::Cell:D {
                put ' ' x 8 ~ '<' ~ @headers[$col] ~ '>' ~ self!subst-ml-text($!body.cells[$row][$col].TEXT) ~ '</' ~ @headers[$col] ~ '>';
            }
        }
        put ' ' x 4 ~ '</row' ~ $row ~ '>';
    }
    put '</root>';
}

method TEXT-print {
    return False unless self!grid-check;
    loop (my $col = 0; $col < $!body.headings.elems; $col++) {
        my $justification   = 'center';
        $justification      = $!body.headings[$col]<justification> with $!body.headings[$col]<justification>;
        print ' ' ~ $!body.headings[$col].TEXT-padded(:width($!body.meta<col-width>[$col]), :$justification);
        print ' ' unless $col == ($!body.headings.elems - 1);
    }
    print "\n"  if $!body.headings.elems;
    loop ($col = 0; $col < $!body.headings.elems; $col++) {
        print ' ' ~ '-' x $!body.meta<col-width>[$col];
        print ' ' unless $col == ($!body.headings.elems - 1);
    }
    print "\n"  if $!body.headings.elems;
    for $!body.meta<sort-order>.list -> $row {
        loop (my $col = 0; $col < $!body.cells[$row].elems; $col++) {
            print ' ';
            given $!body.cells[$row][$col] {
                when Our::Grid::Cell:D  { print $!body.cells[$row][$col].TEXT-padded(:width($!body.meta<col-width>[$col]));  }
                default                 { print ' ' x $!body.meta<col-width>[$col];                                    }
            }
            print ' ' unless $col == ($!body.cells[$row].elems - 1);
        }
        print " \n";
    }
}

method ANSI-print {
    return False unless self!grid-check;
    my $col-width-total = 0;
    for $!body.meta<col-width>.list -> $colw {
        $col-width-total += $colw;
    }
    $col-width-total   += ($!body.meta<col-width>.elems * 3) - 1;
    my $margin          = ($!term-size.cols - ($col-width-total + 2)) div 2;
    if self.title {
        my $left-pad    = ($col-width-total - self.title.chars) div 2;
        my $right-pad   = $col-width-total - self.title.chars - $left-pad;
        put ' ' x $margin ~ %box-char<top-left-corner> ~ %box-char<horizontal> x $col-width-total ~ %box-char<top-right-corner>;
        put ' ' x $margin ~ %box-char<side> ~ ' ' x $left-pad ~ self.title ~ ' ' x $right-pad ~ %box-char<side>;

        print ' ' x $margin ~ %box-char<side-row-left-sep>;
        loop (my $i = 0; $i < ($!body.meta<col-width>.elems - 1); $i++) {
            print %box-char<horizontal> x ($!body.meta<col-width>[$i] + 2) ~ %box-char<down-and-horizontal>;
        }
        put %box-char<horizontal> x ($!body.meta<col-width>[*-1] + 2) ~ %box-char<side-row-right-sep>;
    }
    else {
        print ' ' x $margin ~ %box-char<top-left-corner>;
        loop (my $i = 0; $i < ($!body.meta<col-width>.elems - 1); $i++) {
            print %box-char<horizontal> x ($!body.meta<col-width>[$i] + 2) ~ %box-char<down-and-horizontal>;
        }
        put %box-char<horizontal> x ($!body.meta<col-width>[*-1] + 2) ~ %box-char<top-right-corner>;
    }
    if $!body.headings.elems {
        print ' ' x $margin ~ %box-char<side>;
        loop (my $col = 0; $col < $!body.headings.elems; $col++) {
            print ' ' ~ $!body.headings[$col].ANSI-fmt(:width($!body.meta<col-width>[$col]), :bold, :reverse($!body.meta<reverse-highlight>), :highlight<white>, :foreground<black>).ANSI-padded;
            print ' ' ~ %box-char<side>;
        }
        print "\n";
    }
    for $!body.meta<sort-order>.list -> $row {
        print ' ' x $margin;
        loop (my $col = 0; $col < $!body.cells[$row].elems; $col++) {
            print %box-char<side> ~ ' ';
            given $!body.cells[$row][$col] {
                when Our::Grid::Cell:D  {
                    print $!body.cells[$row][$col].ANSI-fmt(:width($!body.meta<col-width>[$col])).ANSI-padded;
                }
                default                 { print ' ' x $!body.meta<col-width>[$col];                                    }
            }
            print ' ' unless $col == ($!body.cells[$row].elems - 1);
        }
        put ' ' ~ %box-char<side>;
    }
    print ' ' x $margin ~ %box-char<bottom-left-corner>;
    loop (my $i = 0; $i < ($!body.meta<col-width>.elems - 1); $i++) {
        print %box-char<horizontal> x ($!body.meta<col-width>[$i] + 2) ~ %box-char<up-and-horizontal>;
    }
    put %box-char<horizontal> x ($!body.meta<col-width>[*-1] + 2) ~ %box-char<bottom-right-corner>;
}

method TUI {
    return                  unless $*IN.t;
    return False            unless self!grid-check;
    my $erase-char          = qx/stty -a/;
    $erase-char            ~~ s/ ^ .+? \s 'erase' \s '=' \s (..) ';' .+ $ /$0/;
    ui.setup: heights => [ 1, 1, fr => 1, 1];
    my \Title               = ui.panes[0];
    my \Headings            = ui.panes[1];
    my \Body                = ui.panes[2];
    my \Footer              = ui.panes[3];
    Body.auto-scroll        = False;
#   Title
    Title.put: ' ' x ((($!term-size.cols - $!body.title.chars) div 2) - 1) ~ $!body.title;
#   Margin
    my $col-width-total     = 0;
    for $!body.meta<col-width>.list -> $colw {
        $col-width-total   += $colw;
    }
    $col-width-total       += ($!body.meta<col-width>.elems * 2) - 2;
    my $margin              = (($!term-size.cols - $col-width-total) div 2) - 1;
#   Headings
    if $!body.headings.elems {
        my $headings        = ' ' x ($margin - 1);
        loop (my $col = 0; $col < $!body.headings.elems; $col++) {
            $headings          ~= ' ';
            $headings          ~= $!body.headings[$col].TEXT-padded(:width($!body.meta<col-width>[$col]));
            $headings          ~= ' ' unless $col == ($!body.headings.elems - 1);
        }
        Headings.put: $headings;
    }
#   Body
    my $body-record;
    for $!body.meta<sort-order>.list -> $row {
        $body-record = ' ' x $margin;
        loop (my $col = 0; $col < $!body.cells[$row].elems; $col++) {
            $body-record ~= ' ' unless $col == 0;
            given $!body.cells[$row][$col] {
                when Our::Grid::Cell:D  {
                    my $record      = $!body.cells[$row][$col].ANSI-fmt(:width($!body.meta<col-width>[$col])).ANSI-padded;
                    $record         = $record.trim-trailing if $col == ($!body.cells[$row].elems - 1);
                    $body-record   ~= $record;
                }
                default                 {
                    $body-record   ~= ' ' x $!body.meta<col-width>[$col] unless $col == ($!body.cells[$row].elems - 1);
                }
            }
            $body-record ~= ' ' unless $col == ($!body.cells[$row].elems - 1);
        }
        Body.put: $body-record;
    }
    Footer.put: " Press 'q' to quit";
    ui.focus(pane => 2);
    ui.interact;
    ui.shutdown;
    qqx/stty erase $erase-char/;
}

method GUI {
    return                      unless $*IN.t;
    return False                unless self!grid-check;

    my GTK::Simple::App $gui;
    $gui                       .= new(title => $!body.title, :720width, :600height);

    my $grid                    = GTK::Simple::Grid.new;
    loop (my $col = 0; $col < $!body.headings.elems; $col++) {
        my $VBox                = GTK::Simple::VBox.new;
        my $heading             = GTK::Simple::MarkUpLabel.new(text => '<span foreground="black" underline="single" weight="bold" size="large">' ~ $!body.headings[$col].TEXT ~ '</span>');
        $grid.attach:           [$col, 0, 1, 1] => $heading;
        for $!body.meta<sort-order>.list -> $row {
            my $body            = ' ';
            $body               = $!body.cells[$row][$col].TEXT when $!body.cells[$row][$col] ~~ Our::Grid::Cell:D;
            my $obj             = GTK::Simple::TextView.new;
            $obj.text           = $body;
            $obj.editable       = False;
            given $!body.cells[$row][$col].justification {
                when 'left'     { $obj.alignment = LEFT;    }
                when 'center'   { $obj.alignment = CENTER;  }
                when 'right'    { $obj.alignment = RIGHT;   }
                default         { $obj.alignment = FILL;    }
            }
            $obj.monospace      = True;
            $VBox.set-content:  $obj;
        }
        $VBox.border-width      = 20;
        $grid.attach:           [$col, 1, 1, 1] => $VBox;
    }
    $grid.baseline-row:         $!body.meta<sort-order>.elems;
    my $scrolled-grid           = GTK::Simple::ScrolledWindow.new;
    $scrolled-grid.set-content($grid);
    $gui.border-width = 20;
    $gui.set-content($scrolled-grid);
    $gui.run;
}

=finish

    my @cells;
    loop (my $col = 0; $col < $!body.headings.elems; $col++) {
        @cells.push:    [$col, 0, 1, 1] => GTK::Simple::MarkUpLabel.new(text => '<span foreground="black" size="large">' ~ $!body.headings[$col].TEXT ~ '</span>');
    }
    @cells.push:        [0, 1, $!body.headings.elems, 1] => GTK::Simple::Separator.new;
    for $!body.meta<sort-order>.list -> $row {
        loop (my $col = 0; $col < $!body.cells[$row].elems; $col++) {
            my $body    = ' ';
            $body       = $!body.cells[$row][$col].TEXT when $!body.cells[$row][$col] ~~ Our::Grid::Cell:D;
            @cells.push: [$col, ($row + 2), 1, 1] => GTK::Simple::Button.new(label => $body);
        }
    }
    my $grid            = GTK::Simple::Grid.new(@cells);
    my $exit-b          = GTK::Simple::ToggleButton.new(label=>'Exit');
    $exit-b.toggled.tap(-> $b { $gui.exit } );

    my $structure = GTK::Simple::Grid.new(
        [0, 0, 1, 1] => $grid,
        [0, 1, 1, 1] => $exit-b,
    );
#   $structure.column-spacing = 16;
#   $grid.row-spacing = 2;
#   $grid.column-spacing = 4;
    $gui.set-content($structure);
#   $gui.set-content($grid);
#   $gui.border-width = 20;
#   $grid.baseline-row: 4;
    $gui.run;
}

=finish

my $app = GTK::Simple::App.new(title => 'Calendar', height => 300, width => 600);
my $calendar = GTK::Simple::Calendar.new;

my $month-entry = GTK::Simple::Entry.new(text => ~$calendar.month);
my $year-entry  = GTK::Simple::Entry.new(text => ~$calendar.year);
my $day-entry   = GTK::Simple::Entry.new(text => ~$calendar.day);

$calendar.day-selected.tap: {
    $year-entry.text    = .year.Str;
    $month-entry.text   = .month.Str;
    $day-entry.text     = .day.Str;
};

my $date-view = GTK::Simple::Grid.new(
    [0, 0, 1, 1] => GTK::Simple::Label.new(text => "Day"),
    [1, 0, 1, 1] => $day-entry,
    [2, 0, 1, 1] => GTK::Simple::Label.new(text => "Month"),
    [3, 0, 1, 1] => $month-entry,
    [4, 0, 1, 1] => GTK::Simple::Label.new(text => "Year"),
    [5, 0, 1, 1] => $year-entry
);

$date-view.column-spacing = 8;

my $structure = GTK::Simple::Grid.new(
    [0, 0, 1, 1] => $calendar,
    [1, 0, 1, 1] => $date-view
);

$structure.column-spacing = 16;

$app.set-content($structure);

($day-entry, $month-entry).map: { .width-chars = 2 };
$year-entry.width-chars = 4;

$date-view.size-request(300, 120);
$calendar.size-request(300,300);

$app.run;

