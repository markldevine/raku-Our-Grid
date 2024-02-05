#use Our::Grid::Row;
#use Our::Grid::Column;
#unit class Our::Grid:api<1>:auth<Mark Devine (mark@markdevine.com)> does Our::Grid::Row does Our::Grid::Column;
unit class Our::Grid:api<1>:auth<Mark Devine (mark@markdevine.com)>;

use Our::Grid::Cell;
use Our::Utilities;

my constant CORNERS = %(
    ascii  => < + + + + >,
    double => < ╔ ╗ ╚ ╝ >,
    light  => < ┌ ┐ └ ┘ >,
    heavy  => < ┏ ┓ ┗ ┛ >,
    round  => < ╭ ╮ ╰ ╯ >,
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

has $.header;
has $.footer;
has $.term-size;

has $.grid          = Array.new();
has $.current-row   = 0;
has $.current-col   = 0;
has @.col-width;

has $.borders;

submethod TWEAK {
    $!term-size     = term-size;                                            # $term-size.rows $term-size.cols
}

method add-cell (Our::Grid::Cell:D :$cell, :$row, :$col) {
    given $row {
        when Bool   { ++$!current-row;  $row = $!current-row;                                   }
        when Int    { $!current-row     = $row;                                                 }
    }
    given $col {
        when Bool   { ++$!current-col;  $col = $!current-col                                    }
        when Int    { $!current-col     = $col;                                                 }
        default     { $!current-col     = $!grid[$!current-row].elems; $col = $!current-col;    }
    }
put $row ~ ';' ~ $col;
    $!grid[$row]        = Array.new()   unless $!grid[$row];
    @!col-width[$col]   = 0 unless @!col-width[$col];
    @!col-width[$col]   = $cell.text-length if $cell.text-length > @!col-width[$col];
    if $col {
        $!grid[$row][$col] = $cell;
    }
    else {
        $!grid[$row].push: $cell;
    }
}

method TEXT-print {
    loop (my $row = 0; $row < $!grid.elems; $row++) {
        loop (my $col = 0; $col < $!grid[$row].elems; $col++) {
            print '| ';
            print $!grid[$row][$col].TEXT-fmt(:width(@!col-width[$col]));
            print ' ' unless $col == ($!grid[$row].elems - 1);
        }
        print " |\n";
    }
}

method ANSI-print {
    loop (my $row = 0; $row < $!grid.elems; $row++) {
        loop (my $col = 0; $col < $!grid[$row].elems; $col++) {
            print '| ';
            print $!grid[$row][$col].ANSI-fmt(:width(@!col-width[$col]));
            print ' ' unless $col == ($!grid[$row].elems - 1);
        }
        print " |\n";
    }
}

=finish
