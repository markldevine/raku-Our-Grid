unit class Our::Record:api<1>:auth<Mark Devine (mark@markdevine.com)>;

use NativeCall;
use Our::Cell;

has Int     $.number-of-columns;
has Cell    @.cells;
has Int:D   $.max-cells             is required;
has Int:D   $.horizontal-limit      = 0;
has Int:D   $.vertical-expansion    = 0;

has         @.footer;
has         @.header;
has         @.left-margin;
has         @.right-margin;
has         @.records;

submethod TWEAK {
}

method add-cell (Cell:D $cell) {
    die 'Cell limit <' ~ self.max-cells ~ '> exceeded!' if @!cells.elems > self.max-cells;
    @!cells.push: $cell;
}

=finish
