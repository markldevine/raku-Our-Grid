unit class Our::Grid::Cell:api<1>:auth<Mark Devine (mark@markdevine.com)>;

#   *** take out $.row & $.col logic; set them after the full grid is calculated!

use Our::Grid::Cell::Fragment;
use Our::Utilities;

has         $.fragments;
has         $.ANSI              is built;
has         $.text;
has         $.TEXT              is built;
has Bool    $.justify-left      is rw;
has Bool    $.justify-center    is rw;
has Bool    $.justify-right     is rw;
has uint    $.row               is rw;
has uint    $.col               is rw;
has uint    $.visibility        is rw   = 100;      # % of mandatory visibility upon display
has uint    $.width             is rw;
has         $.row-background;
has         %.options;

submethod BUILD(:$text, :$fragments, :$width, :$row, :$col, *%options) {
    die "Must initialize with either ':text' or ':fragments'" unless $text || $fragments;
    $!text          = $text;
    $!width         = $width with $width;
    $!row           = $row with $row;
    $!col           = $col with $col;
    die "Must send both 'row' & 'col' together" if any($!row.so, $!col.so) && ! all($!row.so, $!col.so);
    %!options       = %options;
    $!fragments     = $fragments with $fragments;
    $!fragments[0]  = Our::Grid::Cell::Fragment.new(:$!text, |%options) unless $!fragments;
}

submethod TWEAK {
    for $!fragments.list -> $fragment {
        $!TEXT     ~= $fragment.TEXT-fmt;
    }
    self.ANSI-fmt();
}

#method ANSI-fmt (
#                    ANSI-Colors :$foreground,
#                    ANSI-Colors :$background,
#                                :$bold,
#                                :$faint,
#                                :$italic,
#                                :$underline,
#                                :$blink,
#                                :$reverse,
#                                :$hide,
#                                :$strikethrough,
#                                :$doubleunderline,
#                ) {
method ANSI-fmt (*%options) {
    $!ANSI          = Nil;
    $!ANSI          = sprintf("\o33[%d;%dH", $!row, $!col) if $!row || $!col;
    for $!fragments.list -> $fragment {
        $fragment.foreground        = %options<foreground>      if %options<foreground>:exists;
        unless $!row-background {
            $fragment.background    = %options<background>      if %options<background>:exists;
        }
        $fragment.bold              = %options<bold>            if %options<bold>:exists;
        $fragment.faint             = %options<faint>           if %options<faint>:exists;
        $fragment.italic            = %options<italic>          if %options<italic>:exists;
        $fragment.underline         = %options<underline>       if %options<underline>:exists;
        $fragment.blink             = %options<blink>           if %options<blink>:exists;
        $fragment.reverse           = %options<reverse>         if %options<reverse>:exists;
        $fragment.hide              = %options<hide>            if %options<hide>:exists;
        $fragment.strikethrough     = %options<strikethrough>   if %options<strikethrough>:exists;
        $fragment.doubleunderline   = %options<doubleunderline> if %options<doubleunderline>:exists;
        $!ANSI     ~= $fragment.ANSI-fmt;
    }
}

=finish
