#!/usr/bin/env raku

use lib '/home/mdevine/github.com/raku-Our-Grid/lib';

use Our::Grid;
use Our::Grid::Cell;
use Our::Utilities;

my Our::Grid    $grid  .= new;

my $background          = grey244;
for 'A' .. 'J' -> $data {
    my Our::Grid::Row $row .= new;
    for 1 .. 10 -> $i {
        if $i %% 2 {
            $row.add-cell: Our::Grid::Cell.new(:text($data x 10), :1spaceafter);
        }
        else {
            $row.add-cell: Our::Grid::Cell.new(:text($data x 10), :1spaceafter, :foreground(green));
        }
    }
    if $background = grey244 {
        $grid.add-row: $row, :$background;
        $background = grey254;
    }
    else {
        $grid.add-row: $row, :$background;
        $background = grey244;
    }
}

#$grid.TEXT-out;
$grid.ANSI-out for 1 .. 1;
