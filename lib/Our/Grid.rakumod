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

subset Base64Str of Str where { $_ ~~ /^<[A..Za..z0..9+/=]>+$/ };

our $Grid-Email-Formats is export = set <CSV HTML JSON TEXT XML>;
our subset Grid-Email-Formats is export of Str where { $_ (elem) $Grid-Email-Formats };

#       when $csv           {   $grid.CSV-print;  }
#       when $gui           {   $grid.GUI;        }
#       when $html          {   $grid.HTML-print; }
#       when $json          {   $grid.JSON-print; }
#       when $mailing       {
#                               $grid.send-proxy-mail-via-redis(
#                                   :cro-host<127.0.0.1>,
#                                   :22151cro-port,
#                                   :mail-from($from),
#                                   :@mail-to,
#                                   :@mail-cc,
#                                   :@mail-bcc,
#                                   :$format,
#                               );
#       }
#       when $tab           {   $grid.TAB-print; }
#       when $text          {   $grid.TEXT-print; }
#       when $tui           {   $grid.TUI;        }
#       when $xml           {   $grid.XML-print;  }
#       default             {   $grid.ANSI-print; }

my class Interfaces {
    has Bool                $.csv;
    has Bool                $.gui;
    has Bool                $.html;
    has Bool                $.json;
    has Grid-Email-Formats  $.mail-body-format  is built;
    has Str                 $.mail-from         is built;
    has Email-Address       @.mail-to;
    has Email-Address       @.mail-cc;
    has Email-Address       @.mail-bcc;
    has Int                 @.sort-columns      is built;
    has Bool                $.tab;
    has Bool                $.text;
    has Bool                $.tui;
    has Bool                $.xml;

    submethod BUILD (
                        :$mail-body-format,
                        :$mail-from,
                        :$sort-columns,
                    ) {
    }
}

my class Body {
    has @.cells;
    has @.headings;
    has %.meta;
    has $.title                             is rw           = $*PROGRAM.Str;
}

has                     $.term-size;
has Body                $.body;
has Int                 $.current-row       is rw       = 0;
has Int                 $.current-col       is rw       = 0;
has Cro::HTTP::Client   $.grid-proxy;

has Str                 $.title             is built    = '';
has Bool                $!reverse-highlight is built    = False;

submethod TWEAK {
    $!term-size         = term-size;                                            # $!term-size.rows $!term-size.cols
    $!body             .= new;
    self.title($!title) if $!title;
    self.reverse-highlight($!reverse-highlight);

#say 'ver  = ' ~ $?DISTRIBUTION.meta<ver>;
#say 'api  = ' ~ $?DISTRIBUTION.meta<api>;
#say 'auth = ' ~ $?DISTRIBUTION.meta<auth>;

}

method reverse-highlight (Bool $reverse-highlight?) {
    $!body.meta<reverse-highlight>         = $reverse-highlight with $reverse-highlight;
    return $!body.meta<reverse-highlight>;
}

method title (Str $title?) {
    with $title {
        $!title         = $title;
        $!body.title    = $title;
    }
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
}

method send-proxy-mail-via-redis (
        Str:D               :$cro-host      = '127.0.0.1',
        Int:D               :$cro-port      = 22151,
        Str:D               :$mail-from!,
                            :@mail-to!,
                            :@mail-cc?,
                            :@mail-bcc?,
        Grid-Email-Formats  :$format,
    ) {
    die 'mail-from must be specified!'  without $mail-from;
    die 'mail-to must be specified!'    without @mail-to;
    my $redis-key       = base64-encode($*PROGRAM ~ '_' ~ sprintf("%09d", $*PID) ~ '_' ~ DateTime.now.posix(:real)).decode.encode.Str;
    self.redis-set($redis-key);
    my $Cro-URL         = 'http://'
                        ~ $cro-host
                        ~ ':'
                        ~ $cro-port
                        ~ '/proxy-mail-via-redis'
                        ;
    my %query;
    %query<redis-key>   = $redis-key;
    %query<mail-from>   = $mail-from;
    %query<mail-to>     = @mail-to.join(',');
    %query<mail-cc>     = @mail-cc.join(',')    if @mail-cc.elems;
    %query<mail-bcc>    = @mail-bcc.join(',')   if @mail-bcc.elems;
    %query<format>      = $format;
#   ?term=mountains&images=true

my $remote-host = 'jgstmgtgate1lpv.wmata.local';
my @cmd         = 'ssh', $remote-host, '/bin/curl', '-G', '--silent';
$Cro-URL       ~= '?';
my @query;
for %query.keys.sort -> $key {
    @query.push:    $key ~ '=' ~ %query{$key};
}
$Cro-URL       ~= @query.join('&');
@cmd.push:      "'" ~ $Cro-URL ~ "'";

#dd @cmd;
#put @cmd;
my $proc        = run @cmd, :out, :err;
#say $proc.exitcode;
my $out         = $proc.out.slurp(:close);
my $err         = $proc.err.slurp(:close);
note $err       if $err;
say $out        if $out;


#   my $response        = await Cro::HTTP::Client.get: $Cro-URL, :%query;
#   my $body            = await $response.body;
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

multi method add-cell (Int:D $int!, *%opts) {
    self.add-cell(:cell(Our::Grid::Cell.new(:text($int.Str), |%opts)));
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
###      sort(*.split(/\d+/, :kv).map({ (try .Numeric) // $_}).List)
### 
###  Or more simply:
###   my @h = ( 
###     { 
###       name => "albert", 
###       age => 40, 
###       size => 2 
###     }, 
###     { 
###       name => "andy", 
###       age => 22, 
###       size => 3 
###     }, 
###     { 
###       name => "albert", 
###       age => 69, 
###       size => 3 
###     } 
###   ); 
###   @h.sort( *<name age> ).gist.say;
### Results in: ({age => 40, name => albert, size => 2} {age => 69, name => albert, size => 3} {age => 22, name => andy, size => 3})

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

method CSV-print {
    return False unless self!grid-check;
    csv(in => csv(in => self!datafy), out => $*OUT);
}

method JSON-print {
    put self.to-json;
}

method to-json {
    return False unless self!grid-check;
    return to-json(self!datafy);
}

method HTML-print {
    put self.to-html;
}

method to-html {
    return False unless self!grid-check;
    my $html;
    $html   = '<!DOCTYPE html>' ~ "\n";
    $html  ~= '<html>' ~ "\n";
    $html  ~= ' ' x 4 ~ '<head>' ~ "\n";
    $html  ~= ' ' x 8 ~ '<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">' ~ "\n";
    $html  ~= ' ' x 8 ~ '<title>' ~ self.title ~ '</title>' ~ "\n" if self.title;
    $html  ~= q:to/ENDOFHTMLHEAD/;
            <style>
                table, h1, th, td {
                    margin-left:        auto; 
                    margin-right:       auto;
                    padding:            3px;
                    text-align:         center;
                }
                body {
                    background-color:   #282c34;
                }
                td:hover {
                    background-color: coral;
                }
            </style>
            <style>
                .pheading {
                    background-color:   #009cde;
                    border:             1px solid #9fabbb;
                    font-family:        arial, verdana, sans-serif;
                    font-size:          10pt;
                    font-weight:        bold;
                    margin-bottom:      5px;
                    padding-bottom:     1px;
                    padding-left:       9px;
                    padding-right:      10px;
                    padding-top:        1px;
            }
            </style>
            <style>
                .theading {
                    background-color:   #d0d0d0;
                    border-bottom:      1px solid #cccccc;
                    border-left:        0px solid #cccccc;
                    border-right:       1px solid #cccccc;
                    border-top:         0px solid #cccccc;
                    color:              #000000;
                    font-family:        arial, verdana, sans-serif;
                    font-size:          11pt;
                    font-weight:        bold;
                    margin:             0px;
                    padding-bottom:     1px;
                    padding-left:       5px;
                    padding-right:      5px;
                    padding-top:        0px;
            }
            </style>
            <style>
                .trow-even {
                    background-color:   #f0f0f0;
                    border-bottom:      1px solid #cccccc;
                    border-left:        0px solid #cccccc;
                    border-right:       1px solid #cccccc;
                    border-top:         0px solid #cccccc;
                    color:              #000000;
                    font-family:        arial, verdana, sans-serif;
                    font-size:          10pt;
                    margin:             0px;
                    padding-left:       5px;
                    padding-right:      5px;
                    padding-top:        0px;
                    padding-bottom:     1px;
            }
            </style>
            <style>
                .trow-odd {
                    background-color:   #ffffff;
                    border-bottom:      1px solid #cccccc;
                    border-left:        0px solid #cccccc;
                    border-right:       1px solid #cccccc;
                    border-top:         0px solid #cccccc;
                    color:              #000000;
                    font-family:        arial, verdana, sans-serif;
                    font-size:          10pt;
                    margin:             0px;
                    padding-bottom:     1px;
                    padding-left:       5px;
                    padding-right:      5px;
                    padding-top:        0px;
            }
            </style>
            <style>
                .button {
                    background-color:   #80ff80;
                    border-bottom:      1px solid #000000;
                    border-left:        1px solid #000000;
                    border-right:       1px solid #000000;
                    border-top:         1px solid #000000;
                    color:              #000000;
                    font-family:        arial, verdana, sans-serif;
                    font-size:          10pt;
                    margin:             0px;
                    padding-bottom:     0px;
                    padding-left:       0px;
                    padding-right:      0px;
                    padding-top:        0px;
            }
            </style>
            <script type="text/javascript">
                function toggle-all(param) {
                    var x = document.getElementsByName('collapse-expand');
                    var i;
                    for (i = 0; i < x.length; i++) {
                        x[i].style.display = param;
                    }
                }
                function toggle(id) {
                    var n = document.getElementById(id);
                    n.style.display = (n.style.display!='none' ? 'none' : '' );
                }
            </script>
        </head>
    ENDOFHTMLHEAD
    $html                              ~= ' ' x 4 ~ '<body>' ~ "\n";
    $html                              ~= ' ' x 8 ~ '<div id="1" name="collapse-expand">' ~ "\n";
#   $html                              ~= ' ' x 12 ~ '<table cellSpacing="0" cellPadding="3" bgColor="#FFFFFF" border="1" width="100%">' ~ "\n";
    $html                              ~= ' ' x 12 ~ '<table cellSpacing="0" bgColor="#FFFFFF" border="1">' ~ "\n";
    $html                              ~= ' ' x 16 ~ '<thead>' ~ "\n";
    $html                              ~= ' ' x 20 ~ '<tr>' ~ "\n";
    for $!body.headings.list -> $heading {
        $html                          ~= ' ' x 24 ~ '<td class="theading"; style="text-align: left;">' ~ self!subst-ml-text($heading.TEXT) ~ '</td>' ~ "\n";
    }
    $html                              ~= ' ' x 20 ~ '</tr>' ~ "\n";
    $html                              ~= ' ' x 16 ~ '</thead>' ~ "\n";
    $html                              ~= ' ' x 16 ~ '<tbody>' ~ "\n";
    for $!body.meta<sort-order>.list -> $row {
        $html                          ~= ' ' x 20 ~ '<tr>' ~ "\n";
        loop (my $col = 0; $col < $!body.cells[$row].elems; $col++) {
            if $row %% 2 {
                $html                  ~= ' ' x 24 ~ '<td class="trow-odd" ';
            }
            else {
                $html                  ~= ' ' x 24 ~ '<td class="trow-even" ';
            }
            if $!body.cells[$row][$col] ~~ Our::Grid::Cell:D {
                given $!body.cells[$row][$col] {
                    my @style;
                    if .justification {
                        when .justification eq 'left'   { @style.push:  'text-align: left;';    }
                        when .justification eq 'center' { @style.push:  'text-align: center;';  }
                        when .justification eq 'right'  { @style.push:  'text-align: right;';   }
                    }
                    $html              ~= 'style="' ~ @style.join(' ') ~ '"' if @style;
                    $html              ~= '>';
                    my @span;
                    loop (my $f = 0; $f < .fragments.elems; $f++) {
                        @span[$f]       = '';
                        if .fragments[$f].foreground {
                            @span[$f]  ~= 'color: ' ~ .fragments[$f].foreground ~ ';';
                        }
                        if .fragments[$f].background {
                            @span[$f]  ~= 'background-color: ' ~ .fragments[$f].background   ~ ';';
                        }
                    }
                    if @span.elems {
                        loop (my $f = 0; $f < .fragments.elems; $f++) {
                            if @span[$f] {
                                $html  ~= '<span style="' ~ @span[$f].join(' ') ~ '">' ~ .fragments[$f].TEXT ~ '</span>';
                            }
                            else {
                                $html  ~= '<span>' ~ .fragments[$f].TEXT ~ '</span>';
                            }
                        }
                    }
                    else {
                        $html          ~= self!subst-ml-text($!body.cells[$row][$col].TEXT);
                    }
                }
            }
            else {
                $html ~= '>';
            }
            $html ~= '</td>' ~ "\n";
        }
        $html ~= ' ' x 20 ~ '</tr>' ~ "\n";
    }
    $html ~= ' ' x 16 ~ '</tbody>' ~ "\n";
    $html ~= ' ' x 12 ~ '</table>' ~ "\n";
    $html ~= ' ' x 8 ~ '</div>' ~ "\n";
    $html ~= ' ' x 4 ~ '</body>' ~ "\n";
    $html ~= '</html>';
    return $html;
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

method XML-print {
    put self.to-xml;
}

method to-xml {
    die 'Cannot generate XML without column $!body.headings' unless $!body.headings.elems;
    die '$!body.headings.elems <' ~ $!body.headings.elems ~ '> != <' ~ $!body.cells[0].elems ~ '> $!body.cells[0].elems' unless $!body.headings.elems == $!body.cells[0].elems;
    self!sort-order-check;
    my $xml;
    $xml ~= '<?xml version="1.0" encoding="UTF-8"?>' ~ "\n";
    $xml ~= '<root>' ~ "\n";
    my @headers;
    loop (my $i = 0; $i < $!body.headings.elems; $i++) {
        @headers[$i] = $!body.headings[$i].TEXT;
        @headers[$i] = @headers[$i].subst: ' ', '';
        @headers[$i] = @headers[$i].subst: '%', 'PCT';
    }
    for $!body.meta<sort-order>.list -> $row {
        $xml ~= ' ' x 4 ~ '<row' ~ $row ~ '>' ~ "\n";
        loop (my $col = 0; $col < $!body.cells[$row].elems; $col++) {
            if $!body.cells[$row][$col] ~~ Our::Grid::Cell:D {
                $xml ~= ' ' x 8 ~ '<' ~ @headers[$col] ~ '>' ~ self!subst-ml-text($!body.cells[$row][$col].TEXT) ~ '</' ~ @headers[$col] ~ '>' ~ "\n";
            }
        }
        $xml ~= ' ' x 4 ~ '</row' ~ $row ~ '>' ~ "\n";
    }
    $xml ~= '</root>';
    return $xml;
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
    unless $*IN.t {
        self.TEXT-print;
        return;
    }
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
                    print $!body.cells[$row][$col].ANSI-fmt(:width($!body.meta<col-width>[$col])).ANSI-padded;          #%%% focus here to preserve $!spacebefore of [0]...
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
#   my $exit-b                  = GTK::Simple::ToggleButton.new(label=>'Exit');
#   $exit-b.toggled.tap(-> $b { $gui.exit } );
#   my $VBox                    = GTK::Simple::VBox.new;
#   $VBox.set-content:          $scrolled-grid;
#   $VBox.set-content:          $exit-b;
    $gui.border-width           = 20;
#   $gui.set-content($VBox);
    $gui.set-content($scrolled-grid);
    $gui.run;
}

=finish

<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=us-ascii">
        <title>ISP Sessions</title>
        <style>.paragraph-heading   { font-size: 12pt; font-family: arial, verdana, sans-serif; background-color:#009CDE; font-weight: bold; border: 1px solid #9fabbb; margin-bottom: 5px; padding-left: 9px; padding-right: 10px; padding-top: 1px; padding-bottom: 1px }</style>
        <style>.tabhead     { font-size: 11pt; color: #000000; font-family: arial, verdana, sans-serif; background-color: #d0d0d0; font-weight: bold; border-left: 0px solid #cccccc; border-right: 1px solid #cccccc; border-top: 0px solid #cccccc; border-bottom: 1px solid #cccccc; margin: 0px; padding-left: 5px; padding-right: 5px; padding-top: 0px; padding-bottom: 1px }</style>
        <style>.tabeven     { font-size: 9pt; color: #000000; font-family: arial, verdana, sans-serif; background-color: #f0f0f0; border-left: 0px solid #cccccc; border-right: 1px solid #cccccc; border-top: 0px solid #cccccc; border-bottom: 1px solid #cccccc; margin: 0px; padding-left: 5px; padding-right: 5px; padding-top: 0px; padding-bottom: 1px }</style>
        <style>.tabodd      { font-size: 9pt; color: #000000; font-family: arial, verdana, sans-serif; background-color: white; border-left: 0px solid #cccccc; border-right: 1px solid #cccccc; border-top: 0px solid #cccccc; border-bottom: 1px solid #cccccc; margin: 0px; padding-left: 5px; padding-right: 5px; padding-top: 0px; padding-bottom: 1px }</style>
        <style>.button      { font-size: 10pt; color: #000000; font-family: arial, verdana, sans-serif; background-color: #009CDE; border-left: 1px solid #000000; border-right: 1px solid #000000; border-top: 1px solid #000000; border-bottom: 1px solid #000000; margin: 0px; padding-left: 0px; padding-right: 0px; padding-top: 0px; padding-bottom: 0px } </style>

        <script type="text/javascript">
            function toggleall(parm){ var x = document.getElementsByName('togsection'); var i;for (i = 0; i < x.length; i++) { x[i].style.display =  parm;}}
            function toggle(id){ var n = document.getElementById(id); n.style.display =  (n.style.display!='none' ? 'none' : '' ); }
        </script>
    </head>
    <body style="font-size: 8pt">


<p align="center"><font size="4"><b>ISP status for ISPLC01 at 3/21/2024 8:05:51 AM</b></font></p>
<button class=but onclick="toggleall('');"> Show all </button>   <button class=but onclick="toggleall('none');"> Hide all </button>

<div class=parahead><button class=button onclick="toggle('3');">Show/Hide</button>The following filespaces have not completed their backup within the last 3 days :</div>

<div id="3" name="togsection">



        <br>
        <div class="paragraph-heading">ISPLC01 : 7 Day Summary</div>
        <br>
        <table cellspacing="0" cellpadding="3" bgcolor="#FFFFFF" border="1" width="100%">
            <tr>
                <td class="tabhead"></td>
                <td class="tabhead">5 Mar 24</td>
                <td class="tabhead">6 Mar 24</td>
                <td class="tabhead">7 Mar 24</td>
                <td class="tabhead">8 Mar 24</td>
                <td class="tabhead">9 Mar 24</td>
                <td class="tabhead">10 Mar 24</td>
                <td class="tabhead">11 Mar 24</td>
            </tr>
            <tr>
                <td class="tabeven">ISPLC01  - Number of nodes</td>
                <td class="tabeven">237</td>
                <td class="tabeven">237</td>
                <td class="tabeven">237</td>
                <td class="tabeven">237</td>
                <td class="tabeven">237</td>
                <td class="tabeven">237</td>
                <td class="tabeven"></td>
            </tr>
            <tr>
                <td class="tabodd">ISPLC01  - Total daily backup amount (GB)</td>
                <td class="tabodd">3.1 TB</td>
                <td class="tabodd">2.5 TB</td>
                <td class="tabodd">2.7 TB</td>
                <td class="tabodd">2.7 TB</td>
                <td class="tabodd">2.4 TB</td>
                <td class="tabodd">725.7 GB</td>
                <td class="tabodd"></td>
            </tr>
            <tr>
                <td class="tabeven">ISPLC01  - Total daily restore amount (GB)</td>
                <td class="tabeven">0.0 B</td>
                <td class="tabeven">0.0 B</td>
                <td class="tabeven">0.0 B</td>
                <td class="tabeven">0.0 B</td>
                <td class="tabeven">0.0 B</td>
                <td class="tabeven">0.0 B</td>
                <td class="tabeven"></td>
            </tr>
            <tr>
                <td class="tabodd">ISPLC01  - Total files stored</td>
                <td class="tabodd">471230128</td>
                <td class="tabodd">470920826</td>
                <td class="tabodd">470075221</td>
                <td class="tabodd">469786464</td>
                <td class="tabodd">469895972</td>
                <td class="tabodd">469579526</td>
                <td class="tabodd"></td>
            </tr>
            <tr>
                <td class="tabeven"> ISPLC01  - Total node disk capacity (GB)</td>
                <td class="tabeven"> 12307690</td>
                <td class="tabeven"> 12307690</td>
                <td class="tabeven"> 12307690</td>
                <td class="tabeven"> 12307690</td>
                <td class="tabeven"> 12307690</td>
                <td class="tabeven"> 12307690</td>
                <td class="tabeven"> </td></tr>
            <tr>
                <td class="tabodd"> ISPLC01  - Total rep. ISP space used (GB)</td>
                <td class="tabodd"> 677499</td>
                <td class="tabodd"> 678520</td>
                <td class="tabodd"> 678489</td>
                <td class="tabodd"> 679681</td>
                <td class="tabodd"> 676890</td>
                <td class="tabodd"> 677855</td>
                <td class="tabodd"> </td></tr>
            <tr>
                <td class="tabeven"> ISPLC01  - Total schedule success rate</td>
                <td class="tabeven"> 93</td>
                <td class="tabeven"> 93</td>
                <td class="tabeven"> 91</td>
                <td class="tabeven"> 91</td>
                <td class="tabeven"> 91</td>
                <td class="tabeven"> 85</td>
                <td class="tabeven"></td>
            </tr>
        </table>
      </div>
    </body>
</html>
