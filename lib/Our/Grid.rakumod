unit class Our::Grid:api<1>:auth<Mark Devine (mark@markdevine.com)>;

use Our::Cache;
use Our::Grid::Cell;
use Our::Grid::Cell::Fragment;
use Our::Utilities;
use Text::CSV;
use JSON::Fast;
use JSON::Marshal;
use JSON::Unmarshal;
use Color::Names:api<2>;

enum OUTPUTS (
    csv             => 'Text::CSV',
    html            => '???',
    json            => 'JSON::Fast',
    tui             => 'Terminal::UI',
#   xlsl            => 'Spreadsheet::XLSX',
    xml             => 'LibXML',
);

has         $.title             is rw;
has         $.term-size;
has         $.grid                      = Array.new();
has         @.headings                  = ();
has Int     $.current-row       is rw   = 0;
has Int     $.current-col       is rw   = 0;
has Int     @.col-width;
has Int     @.col-raw-text-width;
has Bool    $.reverse-highlight;
has         @.sort-order                = ();
has         @.column-sort-types         = ();
has         @.column-sort-device-names  = ();
has Int     @.column-sort-device-max    = ();
has         $.cache-file-name;

submethod TWEAK {
    $!term-size             = term-size;                                            # $!term-size.rows $!term-size.cols
    $!cache-file-name       = cache-file-name(:meta($*PROGRAM ~ ' ' ~ @*ARGS.join(' ')));
}

method marshal {
    cache(:$!cache-file-name, :data(marshal($!grid)));
}

method unmarshal {
    $!grid                  = unmarshal(cache(:$!cache-file-name), Our::Grid);
    loop (my $row = 0; $row < $!grid.elems; $row++) {
        loop (my $col = 0; $col < $!grid.elems; $col++) {
            $!grid[$row][$col] = unmarshal($!grid[$row][$col], Our::Grid::Cell);
            loop (my $fragment = 0; $fragment < $!grid[$row][$col].fragments.elems; $fragment++) {
                $!grid[$row][$col].fragments[$fragment] = unmarshal($!grid[$row][$col].fragments[$fragment], Our::Grid::Cell::Fragment);
            }
        }
    }
}

multi method add-heading (Str:D $text!, *%opts) {
    self.add-heading(:cell(Our::Grid::Cell.new(:$text, |%opts)));
}

multi method add-heading (Our::Grid::Cell:D :$cell, *%opts) {
    my $column              = @!headings.elems;
    @!headings.append:      $cell;
    @!col-width[$column]    = 0                     without @!col-width[$column];
    @!col-width[$column]    = $cell.TEXT.Str.chars  if $cell.TEXT.Str.chars > @!col-width[$column];
}

multi method add-cell (Str:D $text!, *%opts) {
    self.add-cell(:cell(Our::Grid::Cell.new(:$text, |%opts)));
}

multi method add-cell (Our::Grid::Cell:D :$cell, :$row, :$col) {
    with $row {
        given $row {
            when Bool   { ++$!current-row if $!grid.elems > 0;          }
            when Int    { $!current-row = $row;                         }
            }
    }
    if $!grid[$!current-row]:!exists {
        $!grid[$!current-row]   = Array.new();
        $!current-col           = 0;
    }
    with $col {
        given $col {
            when Bool   { ++$!current-col                               }
            when Int    { $!current-col = $col;                         }
            default     { $!current-col = $!grid[$!current-row].elems;  }
        }
    }
#   sort inferences
    unless @!column-sort-types[$!current-col]:exists && @!column-sort-types[$!current-col] ~~ sort-string {
        my $proposed-sort-type;
        given $cell.cell-sort-type {
            when sort-digits    { $proposed-sort-type   = sort-digits;  }
            when sort-device    {
                @!column-sort-device-max[$!current-col] = 0 without @!column-sort-device-max[$!current-col];
                if @!column-sort-device-names[$!current-col] {
                    if @!column-sort-device-names[$!current-col] ne $cell.cell-sort-device-name {
                        $proposed-sort-type     = sort-string;
                    }
                    else {
                        $proposed-sort-type     = sort-device;
                        @!column-sort-device-max[$!current-col] = $cell.cell-sort-device-number if $cell.cell-sort-device-number > @!column-sort-device-max[$!current-col];
                    }
                }
                else {
                    $proposed-sort-type         = sort-device;
                    @!column-sort-device-names[$!current-col] = $cell.cell-sort-device-name;
                    @!column-sort-device-max[$!current-col] = $cell.cell-sort-device-number if $cell.cell-sort-device-number > @!column-sort-device-max[$!current-col];
                }
            }
            default             { $proposed-sort-type = sort-string;    }
        }
        @!column-sort-types[$!current-col]  = $proposed-sort-type   without @!column-sort-types[$!current-col];
        @!column-sort-types[$!current-col]  = sort-string           if $proposed-sort-type !~~ @!column-sort-types[$!current-col];
    }
#   width accumulators
    @!col-width[$!current-col]          = 0                     without @!col-width[$!current-col];
    @!col-raw-text-width[$!current-col] = 0                     without @!col-raw-text-width[$!current-col];
    @!col-width[$!current-col]          = $cell.TEXT.Str.chars  if $cell.TEXT.Str.chars > @!col-width[$!current-col];
    @!col-raw-text-width[$!current-col] = $cell.text.Str.chars  if $cell.text.Str.chars > @!col-raw-text-width[$!current-col];
    if $!current-col > $!grid[$!current-row].elems {
        loop (my $i = $col; $i >= 0; $i--) {
            @!col-width[$i]             = 0                 without @!col-width[$i];
            @!col-raw-text-width[$i]    = 0                 without @!col-raw-text-width[$i];
        }
    }
    $!grid[$!current-row][$!current-col++] = $cell;
}

multi method sort-by-columns (:@sort-columns!, :$descending) {
    return False unless self!grid-check;
    my $row-digits          = $!grid.elems;
    $row-digits             = "$row-digits".chars;
    my %sortable-rows;
    my $sort-string;
    loop (my $row = 0; $row < $!grid.elems; $row++) {
        $sort-string        = '';
        for @sort-columns -> $col {
            die '$col (' ~ $col ~ ') out of range for grid! (0 <= col <= ' ~ @!col-width.elems - 1 ~ ')' unless 0 <= $col < @!col-width.elems;
            given @!column-sort-types[$col] {
                when sort-string    { $sort-string ~= $!grid[$row][$col].text.chars ?? $!grid[$row][$col].text ~ '_' !! ' _';                                                                                                                   }
                when sort-digits    { $sort-string ~= sprintf('%0' ~ @!col-raw-text-width[$col] ~ 'd', $!grid[$row][$col].text.chars ?? $!grid[$row][$col].text !! "0") ~ '_';                                                                  }
                when sort-device    { $sort-string ~= $!grid[$row][$col].text.chars ?? sprintf('%0' ~  "@!column-sort-device-max[$col]".chars ~ 'd', $!grid[$row][$col].text.substr(@!column-sort-device-names[$col].chars).Int) ~ '_' !! ' _'; }
            }
        }
        $sort-string       ~= sprintf("%0" ~ $row-digits ~ "d", $row);
        %sortable-rows{$sort-string} = $row;
    }
    @.sort-order            = ();
    for %sortable-rows.keys.sort -> $key {
        @!sort-order.push: %sortable-rows{$key};
    }
    @!sort-order            = @!sort-order.reverse if $descending;
}

method !sort-order-check {
    return True if @!sort-order.elems;
    loop (my $s = 0; $s < $!grid.elems; $s++) {
        @!sort-order.push: $s;
    }
}

method !grid-check {
    return False if @!headings.elems && @!headings.elems != $!grid[0].elems;
#   die '@!headings.elems <' ~ @!headings.elems ~ '> != <' ~ $!grid[0].elems ~ '> $!grid[0].elems' if @!headings.elems && @!headings.elems != $!grid[0].elems;
    self!sort-order-check;
    return True;
}

method !datafy {
    self!sort-order-check;
    my @data    = Array.new();
    for @!headings -> $heading {
        @data[0].push: $heading.TEXT;
    }
    for @!sort-order -> $row {
        loop (my $col = 0; $col < $!grid[$row].elems; $col++) {
            given $!grid[$row][$col] {
                when Our::Grid::Cell:D  { @data[$row + 1].push: $!grid[$row][$col].TEXT;    }
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
    put ' ' x 8 ~ '<h1>' ~ $!title ~ '</h1>' if $!title;
    put ' ' x 8 ~ '<table>';
    put ' ' x 12 ~ '<tr>';
    for @!headings -> $heading {
        put ' ' x 16 ~ '<th>' ~ self!subst-ml-text($heading.TEXT) ~ '</th>';
    }
    put ' ' x 12 ~ '</tr>';
    for @!sort-order -> $row {
        put ' ' x 12 ~ '<tr>';
        loop (my $col = 0; $col < $!grid[$row].elems; $col++) {
            print ' ' x 16 ~ '<td style="';
            if $!grid[$row][$col] ~~ Our::Grid::Cell:D {
                given $!grid[$row][$col] {
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
                print '>' ~ self!subst-ml-text($!grid[$row][$col].TEXT);
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
    die 'Cannot generate XML without column @!headings' unless @!headings.elems;
    die '@!headings.elems <' ~ @!headings.elems ~ '> != <' ~ $!grid[0].elems ~ '> $!grid[0].elems' unless @!headings.elems == $!grid[0].elems;
    self!sort-order-check;
    put '<?xml version="1.0" encoding="UTF-8"?>';
    put '<root>';
    my @headers;
    loop (my $i = 0; $i < @!headings.elems; $i++) {
        @headers[$i] = @!headings[$i].TEXT;
        @headers[$i] = @headers[$i].subst: ' ', '';
        @headers[$i] = @headers[$i].subst: '%', 'PCT';
    }
    for @!sort-order -> $row {
        put ' ' x 4 ~ '<row' ~ $row ~ '>';
        loop (my $col = 0; $col < $!grid[$row].elems; $col++) {
            if $!grid[$row][$col] ~~ Our::Grid::Cell:D {
                put ' ' x 8 ~ '<' ~ @headers[$col] ~ '>' ~ self!subst-ml-text($!grid[$row][$col].TEXT) ~ '</' ~ @headers[$col] ~ '>';
            }
        }
        put ' ' x 4 ~ '</row' ~ $row ~ '>';
    }
    put '</root>';
}

method TEXT-print {
    return False unless self!grid-check;
    loop (my $col = 0; $col < @!headings.elems; $col++) {
        my $justification   = 'center';
        $justification      = @!headings[$col].justification with @!headings[$col].justification;
        print ' ' ~ @!headings[$col].TEXT-padded(:width(@!col-width[$col]), :$justification);
        print ' ' unless $col == (@!headings.elems - 1);
    }
    print "\n"  if @!headings.elems;
    loop ($col = 0; $col < @!headings.elems; $col++) {
        print ' ' ~ '-' x @!col-width[$col];
        print ' ' unless $col == (@!headings.elems - 1);
    }
    print "\n"  if @!headings.elems;
    for @!sort-order -> $row {
        loop (my $col = 0; $col < $!grid[$row].elems; $col++) {
            print ' ';
            given $!grid[$row][$col] {
                when Our::Grid::Cell:D  { print $!grid[$row][$col].TEXT-padded(:width(@!col-width[$col]));  }
                default                 { print ' ' x @!col-width[$col];                                    }
            }
            print ' ' unless $col == ($!grid[$row].elems - 1);
        }
        print " \n";
    }
}

method ANSI-print {
    return False unless self!grid-check;
    my $col-width-total = 0;
    for @!col-width -> $colw {
        $col-width-total += $colw;
    }
    $col-width-total   += (@!col-width.elems * 3) - 1;
    my $margin          = ($!term-size.cols - ($col-width-total + 2)) div 2;
    if $!title {
        my $left-pad    = ($col-width-total - $!title.chars) div 2;
        my $right-pad   = $col-width-total - $!title.chars - $left-pad;
        put ' ' x $margin ~ %box-char<top-left-corner> ~ %box-char<horizontal> x $col-width-total ~ %box-char<top-right-corner>;
        put ' ' x $margin ~ %box-char<side> ~ ' ' x $left-pad ~ $!title ~ ' ' x $right-pad ~ %box-char<side>;

        print ' ' x $margin ~ %box-char<side-row-left-sep>;
        loop (my $i = 0; $i < (@!col-width.elems - 1); $i++) {
            print %box-char<horizontal> x (@!col-width[$i] + 2) ~ %box-char<down-and-horizontal>;
        }
        put %box-char<horizontal> x (@!col-width[*-1] + 2) ~ %box-char<side-row-right-sep>;
    }
    else {
        print ' ' x $margin ~ %box-char<top-left-corner>;
        loop (my $i = 0; $i < (@!col-width.elems - 1); $i++) {
            print %box-char<horizontal> x (@!col-width[$i] + 2) ~ %box-char<down-and-horizontal>;
        }
        put %box-char<horizontal> x (@!col-width[*-1] + 2) ~ %box-char<top-right-corner>;
    }
    if @!headings.elems {
        print ' ' x $margin ~ %box-char<side>;
        loop (my $col = 0; $col < @!headings.elems; $col++) {
#           print ' ' ~ @!headings[$col].ANSI-fmt(:width(@!col-width[$col]), :bold, :reverse($!reverse-highlight), :highlight<white>, :foreground<black>, :justification<center>).ANSI-padded;
            print ' ' ~ @!headings[$col].ANSI-fmt(:width(@!col-width[$col]), :bold, :reverse($!reverse-highlight), :highlight<white>, :foreground<black>).ANSI-padded;
            print ' ' ~ %box-char<side>;
        }
        print "\n";
    }
    for @!sort-order -> $row {
        print ' ' x $margin;
        loop (my $col = 0; $col < $!grid[$row].elems; $col++) {
            print %box-char<side> ~ ' ';
            given $!grid[$row][$col] {
                when Our::Grid::Cell:D  {
                    print $!grid[$row][$col].ANSI-fmt(:width(@!col-width[$col])).ANSI-padded;
                }
                default                 { print ' ' x @!col-width[$col];                                    }
            }
            print ' ' unless $col == ($!grid[$row].elems - 1);
        }
        put ' ' ~ %box-char<side>;
    }
    print ' ' x $margin ~ %box-char<bottom-left-corner>;
    loop (my $i = 0; $i < (@!col-width.elems - 1); $i++) {
        print %box-char<horizontal> x (@!col-width[$i] + 2) ~ %box-char<up-and-horizontal>;
    }
    put %box-char<horizontal> x (@!col-width[*-1] + 2) ~ %box-char<bottom-right-corner>;
}

=finish
