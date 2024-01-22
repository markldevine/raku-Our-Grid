unit class Our::Grid::Cell:api<1>:auth<Mark Devine (mark@markdevine.com)>;

use Our::Grid::Cell::Fragment;
use Our::Utilities;

has         $.fragments;
has         $.ANSI              is built(False);
has         $.text;
has         $.TEXT              is built(False);
has Bool    $.justify-left      is rw;
has Bool    $.justify-center    is rw;
has Bool    $.justify-right     is rw;
has uint    $.row               is rw   = 0;
has uint    $.col               is rw   = 0;
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

method ANSI-fmt (*%options) {
    my %opts;
    %opts                   = %options if %options.elems;
    $!ANSI                  = Nil;
    $!ANSI                  = sprintf("\o33[%d;%dH", $!row, $!col) if $!row || $!col;
    for $!fragments.list -> $fragment {
        $!ANSI             ~= $fragment.ANSI-fmt(|%opts);
    }
}

=finish
