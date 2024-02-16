unit class Our::Grid:api<1>:auth<Mark Devine (mark@markdevine.com)>;

use Our::Grid::Cell;
use Our::Utilities;
use Text::CSV;
use JSON::Fast;
use Color::Names:api<2>;

use Data::Dump::Tree;

enum OUTPUTS (
    csv             => 'Text::CSV',
    html            => '???',
    json            => 'JSON::Fast',
    tui             => 'Terminal::UI',
    xlsl            => 'Spreadsheet::XLSX',
    xml             => 'LibXML',
);

#   ???????????????????????????????????????????????????????????????????
#   ?TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT?
#   ???????????????????????????????????????????????????????????????????
#   ?LLLL?pHHHHHp?pHHHHHp?pHHHHHp?pHHHHHp?pHHHHHp?pHHHHHp?pHHHHHp?RRRR?
#   ?LLLL?p-----p?p-----p?p-----p?p-----p?p-----p?p-----p?p-----p?RRRR?
#   ?LLLL?pAAAAAp?pBBBBBp?pCCCCCp?pDDDDDp?pEEEEEp?pFFFFFp?pGGGGGp?RRRR?
#   ?LLLL?pHHHHHp?pIIIIIp?pKKKKKp?pLLLLLp?pMMMMMp?pNNNNNp?pOOOOOp?RRRR?
#   ?LLLL?pPPPPPp?pQQQQQp?pWWWWWp?pXXXXXp?pYYYYYp?pZZZZZp?p     p?RRRR?
#   ???????????????????????????????????????????????????????????????????
#   fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff

has $.title;
has $.header;
has $.footer;
has $.term-size;

has         $.grid              = Array.new();
has Int     $.current-row       = 0;
has Int     $.current-col       = 0;
has Int     @.col-width;
has Bool    $.row-zero-headings = True;
has Bool    $.reverse-highlight;

submethod TWEAK {
    $!term-size                 = term-size;                                            # $!term-size.rows $!term-size.cols
}

method !datafy {
    my @data                    = Array.new();
    loop (my $row = 0; $row < $!grid.elems; $row++) {
        loop (my $col = 0; $col < $!grid[$row].elems; $col++) {
            given $!grid[$row][$col] {
                when Our::Grid::Cell:D  { @data[$row].push: $!grid[$row][$col].TEXT;    }
                default                 { @data[$row].push: '';                         }
            }
        }
    }
    @data;
}

method csv-print {
    csv(in => csv(in => self!datafy), out => $*OUT);
}

method json-print {
    put to-json(self!datafy);
}

#   put ' ' x 16    ~ 'height: 40px;';
#   put ' ' x 16    ~ 'width: 80px;';
#               table, th, td {
#                   border: 1px solid #cccccc;
#               }
#                   background: #121212;

method html-print {
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
    my $index   = 0;
    if $!row-zero-headings {
        $index++;
        put ' ' x 12 ~ '<tr>';
        loop (my $i = 0; $i < $!grid[0].elems; $i++) {
            put ' ' x 16 ~ '<th>' ~ self!subst-ml-text($!grid[0][$i].TEXT) ~ '</th>';
        }
        put ' ' x 12 ~ '</tr>';
    }
    loop (my $row = $index; $row < $!grid.elems; $row++) {
        put ' ' x 12 ~ '<tr>';
        loop (my $col = 0; $col < $!grid[$row].elems; $col++) {
            print ' ' x 16 ~ '<td style="';
            if $!grid[$row][$col] ~~ Our::Grid::Cell:D {
                given $!grid[$row][$col] {
                    if .justification {
                        when .justification ~~ justify-left     { print 'text-align: left;';   proceed; }
                        when .justification ~~ justify-center   { print 'text-align: center;'; proceed; }
                        when .justification ~~ justify-right    { print 'text-align: right;';  proceed; }
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
    die 'Cannot generate XML if $!row-zero-headings == False' unless $!row-zero-headings;
    put '<?xml version="1.0" encoding="UTF-8"?>';
    put '<root>';
    my $headers = $!grid[0];
    my @headers;
    loop (my $i = 0; $i < $headers.elems; $i++) {
        @headers[$i] = $headers[$i].TEXT;
        @headers[$i] = @headers[$i].subst: ' ', '';
        @headers[$i] = @headers[$i].subst: '%', 'PCT';
    }
    loop (my $row = 1; $row < $!grid.elems; $row++) {
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

method add-cell (Our::Grid::Cell:D :$cell, :$row, :$col) {
    with $row {
        given $row {
            when Bool   { ++$!current-row;                                  }
            when Int    { $!current-row = $row;                             }
        }
    }
    if $!grid[$!current-row]:!exists {
        $!grid[$!current-row]   = Array.new();
        $!current-col               = 0;
    }
    with $col {
        given $col {
            when Bool   { ++$!current-col                               }
            when Int    { $!current-col = $col;                         }
            default     { $!current-col = $!grid[$!current-row].elems;  }
        }
    }
    @!col-width[$!current-col]      = 0                     without @!col-width[$!current-col];
    @!col-width[$!current-col]      = $cell.TEXT.Str.chars  if $cell.TEXT.Str.chars > @!col-width[$!current-col];
    if $!current-col > $!grid[$!current-row].elems {
        loop (my $i = $col; $i >= 0; $i--) {
            @!col-width[$i] = 0                 without @!col-width[$i];
        }
    }
    $!grid[$!current-row][$!current-col++] = $cell;
}

method TEXT-print {
    loop (my $row = 0; $row < $!grid.elems; $row++) {
        loop (my $col = 0; $col < $!grid[$row].elems; $col++) {
            print ' ';
            given $!grid[$row][$col] {
                when Our::Grid::Cell:D  { print $!grid[$row][$col].TEXT-padded(:width(@!col-width[$col]));  }
                default                 { print ' ' x @!col-width[$col];                                    }
            }
            print ' ' unless $col == ($!grid[$row].elems - 1);
        }
        print " \n";
        if $row == 0 && $!row-zero-headings {
            loop (my $col = 0; $col < $!grid[$row].elems; $col++) {
                print ' ' ~ '-' x @!col-width[$col];
                print ' ' unless $col == ($!grid[$row].elems - 1);
            }
            print "\n";
        }
    }
}

method ANSI-print {
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
    loop (my $row = 0; $row < $!grid.elems; $row++) {
        print ' ' x $margin;
        loop (my $col = 0; $col < $!grid[$row].elems; $col++) {
            print %box-char<side> ~ ' ';
            given $!grid[$row][$col] {
                when Our::Grid::Cell:D  {
                    if $row == 0 && $!row-zero-headings {
                        print $!grid[$row][$col].ANSI-fmt(:width(@!col-width[$col]), :bold, :reverse($!reverse-highlight), :highlight<white>, :foreground<black>, :justification(justify-center)).ANSI-padded;
                    }
                    else {
                        print $!grid[$row][$col].ANSI-fmt(:width(@!col-width[$col])).ANSI-padded;
                    }
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
