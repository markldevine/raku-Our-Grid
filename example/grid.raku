#!/usr/bin/env raku

use lib '/home/mdevine/github.com/raku-Our-Grid/lib';

use Data::Dump::Tree;
use Our::Grid;

my Our::Grid $grid .= new;

for 'A' .. 'J' -> $data {
    myy $row = Nil;
    for 1 .. 10 -> $i {
        if $i %% 2 {
            $row.push: Our::Grid::Cell.new(:text($data x $i));
        }
        else {
            $row.push: Our::Grid::Cell.new(:text($data x $i), :italic);
        }
    }
    $grid.add-grid-row: $row;
}

for $grid.rows -> $record {
    for $record.list -> $cell {
        print $cell.ansi ~ "\t";
    }
    print "\n";
}
