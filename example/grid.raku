#!/usr/bin/env raku

use lib '/home/mdevine/github.com/raku-Our-Grid/lib';

use Our::Grid;
use Our::Grid::Cell;
use Our::Utilities;

my Our::Grid    $grid  .= new;

my $background          = gray244;
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
    if $background = gray244 {
        $grid.add-row: $row, :$background;
        $background = gray254;
    }
    else {
        $grid.add-row: $row, :$background;
        $background = gray244;
    }
}

#$grid.TEXT-out;
$grid.ANSI-out for 1 .. 1;
