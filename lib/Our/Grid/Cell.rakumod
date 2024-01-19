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

method ANSI-fmt (
                    ANSI-Colors :$foreground,
                    ANSI-Colors :$background,
                                :$bold,
                                :$faint,
                                :$italic,
                                :$underline,
                                :$blink,
                                :$reverse,
                                :$hide,
                                :$strikethrough,
                                :$doubleunderline,
                ) {
    $!ANSI          = Nil;
    $!ANSI          = sprintf("\o33[%d;%dH", $!row, $!col) if $!row || $!col;
    for $!fragments.list -> $fragment {
        $fragment.foreground        = $foreground   if $foreground;
        $fragment.background        = $background   if $background;
        $fragment.bold              = True  if $bold;
        $fragment.faint             = True  if $faint;
        $fragment.italic            = True  if $italic;
        $fragment.underline         = True  if $underline;
        $fragment.blink             = True  if $blink;
        $fragment.reverse           = True  if $reverse;
        $fragment.hide              = True  if $hide;
        $fragment.strikethrough     = True  if $strikethrough;
        $fragment.doubleunderline   = True  if $doubleunderline;
        $!ANSI     ~= $fragment.ANSI-fmt;
    }
}

=finish
