unit class Our::Grid::Row:api<1>:auth<Mark Devine (mark@markdevine.com)>;

use Our::Grid::Cell;
#use Our::Utilities;

has         @.cells;
has uint    $.my-row            is rw;      # self-aware position
has         $.left-row-header;
has         $.right-row-header;
has         $.column-borders;

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
    my %opts;
    %opts                   = %options if %options.elems;
    my $row;
    for @!cells -> $cell {
        $cell.ANSI-fmt(|%opts);
        $row ~= $cell.ANSI;
    }
    return $row;
}

=finish
