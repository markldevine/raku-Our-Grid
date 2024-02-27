unit class Our::Grid:api<1>:auth<Mark Devine (mark@markdevine.com)>;

use Data::Dump::Tree;
use  Base64::Native;
use Color::Names:api<2>;
use Cro::HTTP::Client;
use JSON::Fast;
use JSON::Marshal;
use JSON::Unmarshal;
use Our::Cache;
use Our::Grid::Cell;
use Our::Grid::Cell::Fragment;
use Our::Utilities;
use Redis::Async;
use Text::CSV;

enum OUTPUTS (
    csv             => 'Text::CSV',
    html            => '1',
    json            => 'JSON::Fast',
    tui             => 'Terminal::UI',
#   xlsl            => 'Spreadsheet::XLSX',
    xml             => 'LibXML',
);

has         $.term-size;
has         $.grid                          = Hash.new;
has         $.cache-file-name;
has Int     $.current-row       is rw       = 0;
has Int     $.current-col       is rw       = 0;

has         $.redis-key;

has         $!title             is built    = '';
has Bool    $.reverse-highlight is built    = False;

submethod TWEAK {
    $!term-size                             = term-size;                                            # $!term-size.rows $!term-size.cols
    $!cache-file-name                       = cache-file-name(:meta($*PROGRAM ~ ' ' ~ @*ARGS.join(' ')));
#   use $!grid as an envelope so that simpler marshalling/unmarshalling the object is possible
#       - reduce adherence to the hierarchical-objects idiom, use more direct data structures
#       - less typed objects in the hierarchy means less custom unmarshalling
#       - directly managing hierarchical data structures herein reduces module sprawl -- a matter of aesthetic taste
    $!grid<cells>                           = Array.new;
    $!grid<headings>                        = Array.new;
    $!grid<meta>                            = Hash.new;
    $!grid<meta><col-width>                 = Array.new;
    $!grid<meta><col-raw-text-width>        = Array.new;
    $!grid<meta><column-sort-device-max>    = Array.new;
    $!grid<meta><reverse-highlight>         = $!reverse-highlight;
    $!grid<meta><sort-order>                = Array.new;
    $!grid<title>                           = $!title;
}

method reverse-highlight (Bool $reverse-highlight?) {
    $!grid<meta><reverse-highlight>         = $!grid<meta><reverse-highlight> with $!grid<meta><reverse-highlight>;
    return $!grid<meta><reverse-highlight>;
}

method title (Str $title?) {
    $!grid<title>   = $title with $title;
    return $!grid<title>;
}

method receive-proxy-mail-via-redis (Str:D :$redis-key!) {
#   die 'No Redis servers file: ~/.redis-servers' unless "$*HOME/.redis-servers".IO ~~ :s;
#   my @redis-servers   = slurp($*HOME ~ '/.redis-servers').split(/\s+/);
#   my $redis           = Redis::Async.new(@redis-servers[0] ~ ':6379');
    my $redis           = Redis::Async.new('127.0.0.1' ~ ':6379');

#   self.unmarshal-to-grid($redis.get($redis-key));

    my $s = $redis.get($redis-key);
#put $s;
#die;
#   self.unmarshal-to-grid($s);
    my $obj             = unmarshal($s, Our::Grid);
ddt $obj;
die;
    $!grid              = unmarshal($redis.get($redis-key), Our::Grid);
dd $!grid;
put $!grid<cells>.elems;
    loop (my $row = 0; $row < $!grid<cells>.elems; $row++) {
        loop (my $col = 0; $col < $!grid<cells>[$row].elems; $col++) {
            loop (my $fragment = 0; $fragment < $!grid<cells>[$row][$col]<fragments>.elems; $fragment++) {
                $!grid<cells>[$row][$col]<fragments>[$fragment] = unmarshal($!grid<cells>[$row][$col]<fragments>[$fragment], Our::Grid::Cell::Fragment);
            }
        }
    }
    loop ($row = 0; $row < $!grid<cells>.elems; $row++) {
        loop (my $col = 0; $col < $!grid<cells>[$row].elems; $col++) {
            $!grid<cells>[$row][$col] = unmarshal($!grid<cells>[$row][$col], Our::Grid::Cell);
        }
    }

#   get-html -> SMTP
}

method send-proxy-mail-via-redis (Str:D :$cro-host = '127.0.0.1', Int:D :$cro-port = 22151) {
    my $redis-key       = base64-encode($*PROGRAM ~ ' ' ~ $*PID ~ DateTime.now.posix).decode.encode.Str;
    self.redis-set($redis-key);
# add options like From:, To:, Cc:, Bcc:, Subj:
    my $Cro-URL         = 'http://'
                        ~ $cro-host
                        ~ ':'
                        ~ $cro-port
                        ~ '/proxy-mail-via-redis'
                        ~ '/' ~ $redis-key
                        ;
put $Cro-URL;
    my $response        = await Cro::HTTP::Client.get($Cro-URL);
    my $body            = await $response.body;
#say $body;
}

method redis-set (Str:D $redis-key!) {
#   die 'No Redis servers file: ~/.redis-servers' unless "$*HOME/.redis-servers".IO ~~ :s;
#   my @redis-servers   = slurp($*HOME ~ '/.redis-servers').split(/\s+/);
#   my $redis           = Redis::Async.new(@redis-servers[0] ~ ':6379');
my $redis = Redis::Async.new('127.0.0.1' ~ ':6379');
    $redis.set($redis-key, self.marshal-from-grid);
    $redis.expireat($redis-key, now + 60);
}

method marshal-from-grid {
    return marshal($!grid);
}

#method redis-get {
#    die 'No Redis servers file: ~/.redis-servers' unless "$*HOME/.redis-servers".IO ~~ :s;
#    my @redis-servers   = slurp($*HOME ~ '/.redis-servers').split(/\s+/);
#    my $redis           = Redis::Async.new(@redis-servers[0] ~ ':6379');
#    self.unmarshal-to-grid($redis.get($!redis-key));
#}

method unmarshal-to-grid (Str:D $string) {
    $!grid              = unmarshal($string, Our::Grid);
put $!grid<cells>.elems;
    loop (my $row = 0; $row < $!grid<cells>.elems; $row++) {
        loop (my $col = 0; $col < $!grid<cells>[$row].elems; $col++) {
            loop (my $fragment = 0; $fragment < $!grid<cells>[$row][$col]<fragments>.elems; $fragment++) {
                $!grid<cells>[$row][$col]<fragments>[$fragment] = unmarshal($!grid<cells>[$row][$col]<fragments>[$fragment], Our::Grid::Cell::Fragment);
            }
        }
    }
    loop ($row = 0; $row < $!grid<cells>.elems; $row++) {
        loop (my $col = 0; $col < $!grid<cells>[$row].elems; $col++) {
            $!grid<cells>[$row][$col] = unmarshal($!grid<cells>[$row][$col], Our::Grid::Cell);
        }
    }
dd $!grid;
}

multi method add-heading (Str:D $text!, *%opts) {
    self.add-heading(:cell(Our::Grid::Cell.new(:$text, |%opts)));
}

multi method add-heading (Our::Grid::Cell:D :$cell, *%opts) {
    my $column              = $!grid<headings>.elems;
    $!grid<headings>.append:      $cell;
    $!grid<meta><col-width>[$column]    = 0                     without $!grid<meta><col-width>[$column];
    $!grid<meta><col-width>[$column]    = $cell.TEXT.Str.chars  if $cell.TEXT.Str.chars > $!grid<meta><col-width>[$column];
}

multi method add-cell (Str:D $text!, *%opts) {
    self.add-cell(:cell(Our::Grid::Cell.new(:$text, |%opts)));
}

multi method add-cell (Our::Grid::Cell:D :$cell, :$row, :$col) {
    with $row {
        given $row {
            when Bool   { ++$!current-row if $!grid<cells>.elems > 0;          }
            when Int    { $!current-row = $row;                         }
            }
    }
    if $!grid<cells>[$!current-row]:!exists {
        $!grid<cells>[$!current-row]   = Array.new();
        $!current-col           = 0;
    }
    with $col {
        given $col {
            when Bool   { ++$!current-col                               }
            when Int    { $!current-col = $col;                         }
            default     { $!current-col = $!grid<cells>[$!current-row].elems;  }
        }
    }
#   sort inferences
    unless $!grid<meta><column-sort-types>[$!current-col]:exists && $!grid<meta><column-sort-types>[$!current-col] ~~ 'string' {
        my $proposed-sort-type;
        given $cell.cell-sort-type {
            when 'digits'       { $proposed-sort-type   = 'digits';     }
            when 'name-number'  {
                $!grid<meta><column-sort-device-max>[$!current-col] = 0 without $!grid<meta><column-sort-device-max>[$!current-col];
                if $!grid<meta><column-sort-device-names>[$!current-col] {
                    if $!grid<meta><column-sort-device-names>[$!current-col] ne $cell.cell-sort-device-name {
                        $proposed-sort-type     = 'string';
                    }
                    else {
                        $proposed-sort-type     = 'name-number';
                        $!grid<meta><column-sort-device-max>[$!current-col] = $cell.cell-sort-device-number if $cell.cell-sort-device-number > $!grid<meta><column-sort-device-max>[$!current-col];
                    }
                }
                else {
                    $proposed-sort-type         = 'name-number';
                    $!grid<meta><column-sort-device-names>[$!current-col] = $cell.cell-sort-device-name;
                    $!grid<meta><column-sort-device-max>[$!current-col] = $cell.cell-sort-device-number if $cell.cell-sort-device-number > $!grid<meta><column-sort-device-max>[$!current-col];
                }
            }
            default             { $proposed-sort-type = 'string';       }
        }
        $!grid<meta><column-sort-types>[$!current-col]  = $proposed-sort-type   without $!grid<meta><column-sort-types>[$!current-col];
        $!grid<meta><column-sort-types>[$!current-col]  = 'string'              if $proposed-sort-type !~~ $!grid<meta><column-sort-types>[$!current-col];
    }
#   width accumulators
    $!grid<meta><col-width>[$!current-col]          = 0                     without $!grid<meta><col-width>[$!current-col];
    $!grid<meta><col-raw-text-width>[$!current-col] = 0                     without $!grid<meta><col-raw-text-width>[$!current-col];
    $!grid<meta><col-width>[$!current-col]          = $cell.TEXT.Str.chars  if $cell.TEXT.Str.chars > $!grid<meta><col-width>[$!current-col];
    $!grid<meta><col-raw-text-width>[$!current-col] = $cell.text.Str.chars  if $cell.text.Str.chars > $!grid<meta><col-raw-text-width>[$!current-col];
    if $!current-col > $!grid<cells>[$!current-row].elems {
        loop (my $i = $col; $i >= 0; $i--) {
            $!grid<meta><col-width>[$i]             = 0                 without $!grid<meta><col-width>[$i];
            $!grid<meta><col-raw-text-width>[$i]    = 0                 without $!grid<meta><col-raw-text-width>[$i];
        }
    }
    $!grid<cells>[$!current-row][$!current-col++] = $cell;
}

multi method sort-by-columns (:@sort-columns!, :$descending) {
    return False unless self!grid-check;
    my $row-digits          = $!grid<cells>.elems;
    $row-digits             = "$row-digits".chars;
    my %sortable-rows;
    my $sort-string;
    loop (my $row = 0; $row < $!grid<cells>.elems; $row++) {
        $sort-string        = '';
        for @sort-columns -> $col {
            die '$col (' ~ $col ~ ') out of range for grid! (0 <= col <= ' ~ $!grid<meta><col-width>.elems - 1 ~ ')' unless 0 <= $col < $!grid<meta><col-width>.elems;
            given $!grid<meta><column-sort-types>[$col] {
                when 'string'       { $sort-string ~= $!grid<cells>[$row][$col].text.chars ?? $!grid<cells>[$row][$col].text ~ '_' !! ' _';                                                                                                                   }
                when 'digits'       { $sort-string ~= sprintf('%0' ~ $!grid<meta><col-raw-text-width>[$col] ~ 'd', $!grid<cells>[$row][$col].text.chars ?? $!grid<cells>[$row][$col].text !! "0") ~ '_';                                                                  }
                when 'name-number'  { $sort-string ~= $!grid<cells>[$row][$col].text.chars ?? sprintf('%0' ~  "$!grid<meta><column-sort-device-max>[$col]".chars ~ 'd', $!grid<cells>[$row][$col].text.substr($!grid<meta><column-sort-device-names>[$col].chars).Int) ~ '_' !! ' _'; }
            }
        }
        $sort-string       ~= sprintf("%0" ~ $row-digits ~ "d", $row);
        %sortable-rows{$sort-string} = $row;
    }
    $!grid<meta><sort-order>    = Array.new;
    for %sortable-rows.keys.sort -> $key {
        $!grid<meta><sort-order>.push: %sortable-rows{$key};
    }
    $!grid<meta><sort-order>    = $!grid<meta><sort-order>.reverse.Array if $descending;
}

method !sort-order-check {
    return True                 if $!grid<meta><sort-order> ~~ Array && $!grid<meta><sort-order>.elems;
    $!grid<meta><sort-order>    = Array.new;
    loop (my $s = 0; $s < $!grid<cells>.elems; $s++) {
        $!grid<meta><sort-order>.push: $s;
    }
}

method !grid-check {
    return False if $!grid<headings>.elems && $!grid<headings>.elems != $!grid<cells>[0].elems;
#   die '$!grid<headings>.elems <' ~ $!grid<headings>.elems ~ '> != <' ~ $!grid<cells>[0].elems ~ '> $!grid<cells>[0].elems' if $!grid<headings>.elems && $!grid<headings>.elems != $!grid<cells>[0].elems;
    self!sort-order-check;
    return True;
}

method !datafy {
    self!sort-order-check;
    my @data    = Array.new();
    for $!grid<headings>.list -> $heading {
        @data[0].push: $heading.TEXT;
    }
    for $!grid<meta><sort-order>.list -> $row {
        loop (my $col = 0; $col < $!grid<cells>[$row].elems; $col++) {
            given $!grid<cells>[$row][$col] {
                when Our::Grid::Cell:D  { @data[$row + 1].push: $!grid<cells>[$row][$col].TEXT;    }
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
    for $!grid<headings>.list -> $heading {
        put ' ' x 16 ~ '<th>' ~ self!subst-ml-text($heading.TEXT) ~ '</th>';
    }
    put ' ' x 12 ~ '</tr>';
    for $!grid<meta><sort-order>.list -> $row {
        put ' ' x 12 ~ '<tr>';
        loop (my $col = 0; $col < $!grid<cells>[$row].elems; $col++) {
            print ' ' x 16 ~ '<td style="';
            if $!grid<cells>[$row][$col] ~~ Our::Grid::Cell:D {
                given $!grid<cells>[$row][$col] {
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
                print '>' ~ self!subst-ml-text($!grid<cells>[$row][$col].TEXT);
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
    die 'Cannot generate XML without column $!grid<headings>' unless $!grid<headings>.elems;
    die '$!grid<headings>.elems <' ~ $!grid<headings>.elems ~ '> != <' ~ $!grid<cells>[0].elems ~ '> $!grid<cells>[0].elems' unless $!grid<headings>.elems == $!grid<cells>[0].elems;
    self!sort-order-check;
    put '<?xml version="1.0" encoding="UTF-8"?>';
    put '<root>';
    my @headers;
    loop (my $i = 0; $i < $!grid<headings>.elems; $i++) {
        @headers[$i] = $!grid<headings>[$i].TEXT;
        @headers[$i] = @headers[$i].subst: ' ', '';
        @headers[$i] = @headers[$i].subst: '%', 'PCT';
    }
    for $!grid<meta><sort-order>.list -> $row {
        put ' ' x 4 ~ '<row' ~ $row ~ '>';
        loop (my $col = 0; $col < $!grid<cells>[$row].elems; $col++) {
            if $!grid<cells>[$row][$col] ~~ Our::Grid::Cell:D {
                put ' ' x 8 ~ '<' ~ @headers[$col] ~ '>' ~ self!subst-ml-text($!grid<cells>[$row][$col].TEXT) ~ '</' ~ @headers[$col] ~ '>';
            }
        }
        put ' ' x 4 ~ '</row' ~ $row ~ '>';
    }
    put '</root>';
}

method TEXT-print {
    return False unless self!grid-check;
    loop (my $col = 0; $col < $!grid<headings>.elems; $col++) {
        my $justification   = 'center';
        $justification      = $!grid<headings>[$col].justification with $!grid<headings>[$col].justification;
        print ' ' ~ $!grid<headings>[$col].TEXT-padded(:width($!grid<meta><col-width>[$col]), :$justification);
        print ' ' unless $col == ($!grid<headings>.elems - 1);
    }
    print "\n"  if $!grid<headings>.elems;
    loop ($col = 0; $col < $!grid<headings>.elems; $col++) {
        print ' ' ~ '-' x $!grid<meta><col-width>[$col];
        print ' ' unless $col == ($!grid<headings>.elems - 1);
    }
    print "\n"  if $!grid<headings>.elems;
    for $!grid<meta><sort-order>.list -> $row {
        loop (my $col = 0; $col < $!grid<cells>[$row].elems; $col++) {
            print ' ';
            given $!grid<cells>[$row][$col] {
                when Our::Grid::Cell:D  { print $!grid<cells>[$row][$col].TEXT-padded(:width($!grid<meta><col-width>[$col]));  }
                default                 { print ' ' x $!grid<meta><col-width>[$col];                                    }
            }
            print ' ' unless $col == ($!grid<cells>[$row].elems - 1);
        }
        print " \n";
    }
}

method ANSI-print {
    return False unless self!grid-check;
    my $col-width-total = 0;
    for $!grid<meta><col-width>.list -> $colw {
        $col-width-total += $colw;
    }
    $col-width-total   += ($!grid<meta><col-width>.elems * 3) - 1;
    my $margin          = ($!term-size.cols - ($col-width-total + 2)) div 2;
    if self.title {
        my $left-pad    = ($col-width-total - self.title.chars) div 2;
        my $right-pad   = $col-width-total - self.title.chars - $left-pad;
        put ' ' x $margin ~ %box-char<top-left-corner> ~ %box-char<horizontal> x $col-width-total ~ %box-char<top-right-corner>;
        put ' ' x $margin ~ %box-char<side> ~ ' ' x $left-pad ~ self.title ~ ' ' x $right-pad ~ %box-char<side>;

        print ' ' x $margin ~ %box-char<side-row-left-sep>;
        loop (my $i = 0; $i < ($!grid<meta><col-width>.elems - 1); $i++) {
            print %box-char<horizontal> x ($!grid<meta><col-width>[$i] + 2) ~ %box-char<down-and-horizontal>;
        }
        put %box-char<horizontal> x ($!grid<meta><col-width>[*-1] + 2) ~ %box-char<side-row-right-sep>;
    }
    else {
        print ' ' x $margin ~ %box-char<top-left-corner>;
        loop (my $i = 0; $i < ($!grid<meta><col-width>.elems - 1); $i++) {
            print %box-char<horizontal> x ($!grid<meta><col-width>[$i] + 2) ~ %box-char<down-and-horizontal>;
        }
        put %box-char<horizontal> x ($!grid<meta><col-width>[*-1] + 2) ~ %box-char<top-right-corner>;
    }
    if $!grid<headings>.elems {
        print ' ' x $margin ~ %box-char<side>;
        loop (my $col = 0; $col < $!grid<headings>.elems; $col++) {
            print ' ' ~ $!grid<headings>[$col].ANSI-fmt(:width($!grid<meta><col-width>[$col]), :bold, :reverse($!grid<meta><reverse-highlight>), :highlight<white>, :foreground<black>).ANSI-padded;
            print ' ' ~ %box-char<side>;
        }
        print "\n";
    }
    for $!grid<meta><sort-order>.list -> $row {
        print ' ' x $margin;
        loop (my $col = 0; $col < $!grid<cells>[$row].elems; $col++) {
            print %box-char<side> ~ ' ';
            given $!grid<cells>[$row][$col] {
                when Our::Grid::Cell:D  {
                    print $!grid<cells>[$row][$col].ANSI-fmt(:width($!grid<meta><col-width>[$col])).ANSI-padded;
                }
                default                 { print ' ' x $!grid<meta><col-width>[$col];                                    }
            }
            print ' ' unless $col == ($!grid<cells>[$row].elems - 1);
        }
        put ' ' ~ %box-char<side>;
    }
    print ' ' x $margin ~ %box-char<bottom-left-corner>;
    loop (my $i = 0; $i < ($!grid<meta><col-width>.elems - 1); $i++) {
        print %box-char<horizontal> x ($!grid<meta><col-width>[$i] + 2) ~ %box-char<up-and-horizontal>;
    }
    put %box-char<horizontal> x ($!grid<meta><col-width>[*-1] + 2) ~ %box-char<bottom-right-corner>;
}

=finish
