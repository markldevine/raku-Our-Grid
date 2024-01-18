unit class Our::Grid::Row:api<1>:auth<Mark Devine (mark@markdevine.com)>;

use Our::Grid::Cell;
use Data::Dump::Tree;

has                 @.cells;
has                 $.left-row-header;
has                 $.right-row-header;

method add-cell (Our::Grid::Cell:D $cell) {
    @!cells.push: $cell;
}

method TEXT-fmt {
    my $row = '|';
    for self.cells -> $cell {
        $row ~= $cell.TEXT ~ '|';
    }
    return $row;
}

method ANSI-fmt {
    my $row = '|';
    for @!cells -> $cell {
        $row ~= $cell.ANSI ~ '|';
    }
    return $row;
}

=finish
