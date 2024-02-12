unit class Our::Grid:api<1>:auth<Mark Devine (mark@markdevine.com)>;

use Our::Grid::Cell;
use Our::Utilities;

enum OUTPUTS is export (
    json            => 'JSON::Fast',
    tui             => 'Terminal::UI',
    xlsl            => 'Spreadsheet::XLSX',
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

has $.borders;

submethod TWEAK {
    $!term-size     = term-size;                                            # $!term-size.rows $!term-size.cols
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

#| Character Cell Graphics Set
my  %box-char = (
        side                => '│',
        horizontal          => '─',
        down-and-horizontal => '┬', 
        up-and-horizontal   => '┴',
        top-left-corner     => '┌',
        top-right-corner    => '┐',
        bottom-left-corner  => '└',
        bottom-right-corner => '┘',
        side-row-left-sep   => '├',
        side-row-right-sep  => '┤',
    );

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
                        print $!grid[$row][$col].ANSI-fmt(:width(@!col-width[$col]), :bold, :reverse($!reverse-highlight), :highlight(gray254), :foreground(black), :justification(justify-center)).ANSI-padded;
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
