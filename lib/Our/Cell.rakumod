unit class Our::Grid:api<1>:auth<Mark Devine (mark@markdevine.com)>;

#   https://en.wikipedia.org/wiki/ANSI_escape_code#3-bit_and_4-bit

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

enum ANSI-Colors is export (
    reset               => 0,
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

enum ANSI-Effects is export (
    bold                => 1,
    faint               => 2,
    italic              => 3,
    underline           => 4,
    blink               => 5,
    reverse             => 7,
    hide                => 8,
    strikethrough       => 9,
    doubleunderline     => 21,
    superscript         => 73,
    subscript           => 74,
    allcaps             => 1_000_000,
    alllower            => 1_000_001,
    titlecase           => 1_000_002,
    titlecaselowercase  => 1_000_003,
);

sub ANSI-fmt (
        Str:D           :$text!,
        ANSI-Colors     :$fg,
        ANSI-Colors     :$bg,
        :$ef
    ) is export {
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
        @effects.push: $e.value if $e ~~ ANSI-Effects && 1 <= $e < 60;
    }
    return sprintf("%s%s%s%s%s",
        @effects.elems  ?? "\o33[" ~ @effects.join(';') ~ 'm'       !! '',
        $foreground     ?? "\o33[38;5;" ~ $foreground.value ~ 'm'   !! '',
        $background     ?? "\o33[48;5;" ~ $background.value ~ 'm'   !! '',
        $text,
        ($foreground || $background || @effects.elems) ?? "\o33[0m" !! ''
    );
}

class Point {
    has $.x;
    has $.y;
}

class Phrase {
    has Int     $.foreground            = reset;        # \o33[38;5;<n>m    TEXT    \o33[39m
    has Int     $.background            = reset;        # \o33[48;5;<n>m    TEXT    \o33[49m
    has Bool    $.bold;                                 # \o33[1m           TEXT    \o33[22m
    has Bool    $.faint;                                # \o33[2m           TEXT    \o33[22m
    has Bool    $.italic;                               # \o33[3m           TEXT    \o33[23m
    has Bool    $.underline;                            # \o33[4m           TEXT    \o33[24m
    has Bool    $.blink;                                # \o33[5m           TEXT    \o33[25m
    has Bool    $.reverse;                              # \o33[7m           TEXT    \o33[27m
    has Bool    $.hide;                                 # \o33[8m           TEXT    \o33[28m
    has Bool    $.strikethrough;                        # \o33[9m           TEXT    \o33[29m
    has Bool    $.doubleunderline;                      # \o33[21m          TEXT    \o33[24m
    has Bool    $.superscript;
    has Bool    $.subscript;
    has Bool    $.allcaps;
    has Bool    $.alllower;
    has Bool    $.titlecase;
    has Bool    $.titlecaselowercase;
    has Str:D   $.text                  is required;
}

=finish

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
