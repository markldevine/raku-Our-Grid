unit class Our::Grid::Row:api<1>:auth<Mark Devine (mark@markdevine.com)>;

use Our::Grid::Cell;

has                 @.cells;
has                 $.left-row-header;
has                 $.right-row-header;
has                 $.background;

method add-cell (Our::Grid::Cell:D $cell) {
    @!cells.push: $cell;
}

method TEXT-fmt {
    my $row;
    for self.cells -> $cell {
        $row ~= $cell.TEXT;
    }
    return $row;
}

multi method ANSI-fmt {
    my $row;
    for @!cells -> $cell {
        $row ~= $cell.ANSI;
    }
    return $row;
}

multi method ANSI-fmt (*%options where $_.elems) {
    my $row;
%%% add :background if it is set...
    for @!cells -> $cell {
        $cell.ANSI-fmt(|%options);
        $row ~= $cell.ANSI;
    }
    return $row;
}

=finish
