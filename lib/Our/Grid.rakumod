unit class Our::Grid:api<1>:auth<Mark Devine (mark@markdevine.com)>;

class Cell {
    has Str $.effects;
    has Mu  $.data;
}

class Record {
    has Cell    @.cells;
    has Int:D   @.max-cells             is required;
    has Bool    $.horizontal-limit      = 0;
    has Bool    $.vertical-expansion    = 0;

    method add-cell (Cell:D $cell) {
        die 'Cell limit <' ~ self.cell-limit ~ '> exceeded!' if @!cells.elems > self.cell-limit;
        @!cells.push: $cell;
    }
}

has Record  @.records;

submethod TWEAK {
    ;
}

method add-record (Record:D $record!) {
    @!records.push: $record;
}

=finish
