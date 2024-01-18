unit class Our::Grid::Cell:api<1>:auth<Mark Devine (mark@markdevine.com)>;

#   *** take out $.row & $.col logic; set them after the full grid is calculated!

use Our::Grid::Cell::Fragment;

has         $.fragments;
has         $.ANSI          is built;
has         $.text;
has         $.TEXT          is built;
has uint    $.width         = 0;
has uint    $.row           is rw;
has uint    $.col           is rw;
has uint    $.visibility    = 100;              # % of mandatory visibility upon display
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
    $!ANSI          = sprintf("\o33[%d;%dH", $!row, $!col) if $!row || $!col;
    for $!fragments.list -> $fragment {
        $!ANSI     ~= $fragment.ANSI-fmt;
    }
}

=finish
