unit class Our::Grid:api<1>:auth<Mark Devine (mark@markdevine.com)>;

class Cell {
    has Str $.effects;
    has Mu  $.data;
}

class Row {
    has Int     $.number-of-columns;
    has Record  $.record;
}

class Record {
    has Cell    @.cells;
    has Int:D   @.max-cells             is required;
    has Int:D   $.horizontal-limit      = 0;
    has Int:D   $.vertical-expansion    = 0;

    method add-cell (Cell:D $cell) {
        die 'Cell limit <' ~ self.cell-limit ~ '> exceeded!' if @!cells.elems > self.cell-limit;
        @!cells.push: $cell;
    }
}

has @.footer;
has @.header;
has @.left-margin;
has @.right-margin;
has @.records;

submethod TWEAK {
    ;
}

method add-grid-record ($record!) {
    @!records.push: $record;
}

=finish
