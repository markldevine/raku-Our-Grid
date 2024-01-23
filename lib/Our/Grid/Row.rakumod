unit class Our::Grid::Row:api<1>:auth<Mark Devine (mark@markdevine.com)>;

use Our::Grid::Cell;
#use Our::Utilities;

has         @.cells;
has uint    $.my-row            is rw;      # self-aware position
has         $.left-row-header;
has         $.right-row-header;
has         $.column-borders    is rw;

method add-cell (Our::Grid::Cell:D $cell) {
    @!cells.push: $cell;
}

method TEXT-fmt (*%options) {
    my $row;
    my %opts;
    %opts       = %options if %options.elems;
    for self.cells -> $cell {
        $cell.TEXT-fmt(|%opts);
        $row   ~= $cell.TEXT;
    }
    return $row;
}

method ANSI-fmt (*%options) {
    my %opts;
    %opts       = %options if %options.elems;
    my $row;
    for @!cells -> $cell {
        $cell.ANSI-fmt(|%opts);
        $row   ~= $cell.ANSI;
    }
    return $row;
}

=finish
