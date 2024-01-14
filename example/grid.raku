#!/usr/bin/env raku

use lib '/home/mdevine/github.com/raku-Our-Grid/lib';

use Data::Dump::Tree;
use Our::Grid;
use Terminal::ANSIColor;

my Our::Grid $grid .= new;
my $record          = [];

for 'A' .. 'J' -> $data {
    $record = Nil;
    for 1 .. 10 -> $i {
        if $i %% 2 {
            $record.push: Our::Grid::Cell.new(:data($data x $i));
        }
        else {
            $record.push: Our::Grid::Cell.new(:data($data x $i), :effects());
        }
    }
    $grid.add-grid-record: $record;
}

#ddt $grid;

for $grid.records -> $record {
    put $record.list.map({ .data }).join("\t");
}
