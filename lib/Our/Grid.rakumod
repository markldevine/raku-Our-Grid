unit class Our::Grid:api<1>:auth<Mark Devine (mark@markdevine.com)>;

use NativeCall;
use Our::Phrase

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

class Point {
    has $.x;
    has $.y;
}

class Cell {
    has Point   $.position;
    has Str     $.ANSI-string;
    has         $.phrases;
    has Int     $.width;

    submethod TWEAK {
    }

    method ansi { return ANSI(:$!text, :fg($!foreground), :bg($!background), :ef($!effects)); }
}

class Record {
    has Int     $.number-of-columns;
    has Cell    @.cells;
    has Int:D   $.max-cells             is required;
    has Int:D   $.horizontal-limit      = 0;
    has Int:D   $.vertical-expansion    = 0;

    method add-cell (Cell:D $cell) {
        die 'Cell limit <' ~ self.cell-limit ~ '> exceeded!' if @!cells.elems > self.cell-limit;
        @!cells.push: $cell;
    }
}

has         @.footer;
has         @.header;
has         @.left-margin;
has         @.right-margin;
has         @.records;

has Int $.rows                          = 0;
has Int $.cols                          = 0;

submethod TWEAK {
    my $winsize = term-size;
    $!rows      = $winsize.rows;
    $!cols      = $winsize.cols;
}

method add-grid-record ($record!) {
    @!records.push: $record;
}

=finish
