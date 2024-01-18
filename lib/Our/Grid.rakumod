unit class Our::Grid:api<1>:auth<Mark Devine (mark@markdevine.com)>;

#   Grow the Grid dynamically by adding Our::Grid::Row objects
#       - adjust row count
#       - adjust col count
#       - adjust $!row & $!col in each cell, now that we know where they should be (ANSI-only)
#   method grid-out
#       - construct a [row;col] array with the Cell objects
#       - evoke either TEXT or ANSI to .put
#

use NativeCall;
use Our::Grid::Cell;

has         $.header;
has         $.footer;
has         @.rows;
has         $.window-size;

class winsize is repr('CStruct') {
    has uint16 $.rows;
    has uint16 $.cols;
    has uint16 $.xpixels;
    has uint16 $.ypixels;
    method gist() {
        return "rows={self.rows} cols={self.cols} {self.xpixels}x{self.ypixels}"
    }
}

constant TIOCGWINSZ = 0x5413;

sub term-size(--> winsize) {
    sub ioctl(int32 $fd, int32 $cmd, winsize $winsize) is native {*}
    my winsize $winsize .= new;
    ioctl(0,TIOCGWINSZ,$winsize);
    return $winsize;
}

submethod TWEAK {
    $!term-size = term-size;
#                 $term-size.rows;
#                 $term-size.cols;
}

method add-row ($record!) {
    @!rows.push: $record;
}

#   ???????????????????????????????????????????????????????????????????
#   ?hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh?
#   ???????????????????????????????????????????????????????????????????
#   ?LLLL?pHHHHHp?pHHHHHp?pHHHHHp?pHHHHHp?pHHHHHp?pHHHHHp?pHHHHHp?RRRR?
#   ?LLLL?p-----p?p-----p?p-----p?p-----p?p-----p?p-----p?p-----p?RRRR?
#   ?LLLL?pAAAAAp?pBBBBBp?pCCCCCp?pDDDDDp?pEEEEEp?pFFFFFp?pGGGGGp?RRRR?
#   ?LLLL?pHHHHHp?pIIIIIp?pKKKKKp?pLLLLLp?pMMMMMp?pNNNNNp?pOOOOOp?RRRR?
#   ?LLLL?pPPPPPp?pQQQQQp?pWWWWWp?pXXXXXp?pYYYYYp?pZZZZZp?p     p?RRRR?
#   ???????????????????????????????????????????????????????????????????
#   fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff

method build-grid {
}

method TEXT-out {
    for @!rows -> $row {
        for $row.cells -> $cell {
            put $cell.TEXT;
        }
    }
}

#   *** this could be threaded/hyper if everything is addressed with ANSI position sequences...
method ANSI-out {
    for @!rows -> $row {
        for $row.cells -> $cell {
            print $cell.ANSI;
        }
        print "\n";
    }
}

=finish
unit class Our::Grid::Row:api<1>:auth<Mark Devine (mark@markdevine.com)>;

use Our::Grid::Cell;

has Our::Grid::Cell @.cells;
has                 $.left-row-header;
has                 $.right-row-header;

method add-cell (Cell:D $cell) {
    @!cells.push: $cell;
}

=finish
