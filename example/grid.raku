#!/usr/bin/env raku

use lib '/home/mdevine/github.com/raku-Our-Grid/lib';

use Our::Grid;
use Our::Grid::Cell;
use Our::Grid::Cell::Fragment;

my Our::Grid        $grid  .= new;

for 'A' .. 'J' -> $data {
    my Our::Grid::Row $row .= new;
    for 1 .. 10 -> $i {
        if $i %% 2 {
            $row.add-cell: Our::Grid::Cell.new(:text($data x $i), :1spaceafter);
        }
        else {
            $row.add-cell: Our::Grid::Cell.new(:text($data x $i), :1spaceafter, :italic, :foreground(green));
        }
    }
    $grid.add-row: $row;
}

#$grid.TEXT-out;
$grid.ANSI-out for 1 .. 5;
