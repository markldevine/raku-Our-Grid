unit class Our::Grid:api<1>:auth<Mark Devine (mark@markdevine.com)>;

use NativeCall;

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

enum Text-Colors is export (
    black               => 16,
    blue                => 21,
    cyan                => 51,
    green               => 46,
    magenta             => 201,
    orange              => 202,
    red                 => 196,
    white               => 231,
    yellow              => 226,
);

enum Text-Effects is export (
    bold         => 1,
    faint        => 2,
    italic       => 3,
    underline    => 4,
    blink        => 5,
    invert       => 7,
    hide         => 8,
    strike       => 9,
);

sub color (Str:D :$text!, Text-Colors :$fg, Text-Colors :$bg, :$ef) {
    my $foreground = $fg;
    my $background = $bg;
    my @e;
    given $ef {
        when Positional { @e = $_.flat; }
        when Str        { @e = ($_);    }
        when Int        { @e = ($_);    }
    }
    my @effects;
    for @e -> $e {
        @effects.push: $e.value if $e ~~ Text-Effects && 1 <= $e < 60;
    }
    printf("%s%s%s%s%s\n",
        @effects.elems  ?? "\o33[" ~ @effects.join(';') ~ 'm'       !! '',
        $foreground     ?? "\o33[38;5;" ~ $foreground.value ~ 'm'   !! '',
        $background     ?? "\o33[48;5;" ~ $background.value ~ 'm'   !! '',
        $text,
        ($foreground || $background || @effects.elems) ?? "\o33[0m" !! ''
    );
}

#color(:text("black + black-contrast"),      :fg(black),     :ef(invert));

class Point {
    has $.x;
    has $.y;
}

class Cell {
    has Point   $.position;
    has Int     $.foreground            = 0;
    has Int     $.background            = 0;
    has Mu      $.effects               = ();
    has Str:D   $.text                  is required;
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
has Record  @.records;

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
