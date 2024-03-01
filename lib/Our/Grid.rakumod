unit class Our::Grid:api<1>:auth<Mark Devine (mark@markdevine.com)>;

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
use Terminal::UI;

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
    my $column              = $!body.headings.elems;
    $!body.headings.append:      $cell;
    $!body.meta<col-width>[$column]    = 0                     without $!body.meta<col-width>[$column];
    $!body.meta<col-width>[$column]    = $cell.TEXT.Str.chars  if $cell.TEXT.Str.chars > $!body.meta<col-width>[$column];
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
                when 'string'       { $sort-string ~= $!body.cells[$row][$col].text.chars ?? $!body.cells[$row][$col].text ~ '_' !! ' _';                                                                                                                   }
                when 'digits'       { $sort-string ~= sprintf('%0' ~ $!body.meta<col-raw-text-width>[$col] ~ 'd', $!body.cells[$row][$col].text.chars ?? $!body.cells[$row][$col].text !! "0") ~ '_';                                                                  }
                when 'name-number'  { $sort-string ~= $!body.cells[$row][$col].text.chars ?? sprintf('%0' ~  "$!body.meta<column-sort-device-max>[$col]".chars ~ 'd', $!body.cells[$row][$col].text.substr($!body.meta<column-sort-device-names>[$col].chars).Int) ~ '_' !! ' _'; }
            }
        }
        $sort-string       ~= sprintf("%0" ~ $row-digits ~ "d", $row);
        %sortable-rows{$sort-string} = $row;
    }
    $!body.meta<sort-order>    = Array.new;
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
    my $screen  = Terminal::UI::Screen.new;
    my $frame   = $screen.add-frame;
    my @panes   = $frame.add-panes(heights => [1,1, fr => 1]);
#ui.setup: heights => [ 1, 1, fr => 1];
#my \Title       = ui.panes[0];
#my \Headings    = ui.panes[1];
#my \Body        = ui.panes[2];

my \Title       = @panes[0];
my \Headings    = @panes[1];
my \Body        = @panes[2];

Title.put: "Grid Title";
#Headings.put: "H1  H2  H3  H4       H5    H6   H7", meta => :planet<earth>;
Headings.put: "H1  H2  H3  H4       H5    H6   H7";
#Body.put: "",  meta => :planet<mars>;
Body.put: "11111111111111111111";
Body.put: "  222222222222222222";
Body.put: "    3333333333333333";
$screen.interact;
$screen.shutdown;
}

=finish
