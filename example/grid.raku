#!/usr/bin/env raku

use lib '/home/mdevine/github.com/raku-Our-Grid/lib';

use Data::Dump::Tree;
use Our::Phrase;

my $text    = 'a' .. 'z';

my Our::Phrase $phrase .= new(:$text);
ddt $phrase;
put $phrase.text;


=finish

my Our::Grid $grid .= new;

my $record          = [];

for 'A' .. 'J' -> $data {
    $record = Nil;
    for 1 .. 10 -> $i {
        if $i %% 2 {
            $record.push: Our::Grid::Cell.new(:text($data x $i));
        }
        else {
            $record.push: Our::Grid::Cell.new(:text($data x $i), :effects(blink));
        }
    }
    $grid.add-grid-record: $record;
}

for $grid.records -> $record {
    for $record.list -> $cell {
        print $cell.ansi ~ "\t";
    }
    print "\n";
}
