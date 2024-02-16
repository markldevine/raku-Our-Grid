#!/usr/bin/env raku

use lib '/home/mdevine/github.com/raku-Our-Grid/lib';

use Our::Grid;
use Our::Grid::Cell;
use Our::Utilities;
use Data::Dump::Tree;

my Our::Grid    $grid  .= new: :title('Test Title'), :row-zero-headings(False);

my $max-rows    = 11;
my $max-cols    = 5;
loop (my $row = 0; $row < $max-rows; $row++) {
    loop (my $col = 0; $col < $max-cols; $col++) {
        $grid.add-cell(:cell(Our::Grid::Cell.new(:text(DateTime.new(now)))), :$row, :$col);
#       $grid.add-cell(:cell(Our::Grid::Cell.new(:text(DateTime.new(now)), :foreground<red>)), :$row, :$col);
#       $grid.add-cell(:cell(Our::Grid::Cell.new(:text(DateTime.new(now)), :foreground<green>, :background<yellow>)), :$row, :$col);
#       $grid.add-cell(:cell(Our::Grid::Cell.new(:text($row ~ ';' ~ $col), :foreground<white>, :justification(justify-right))), :$row, :$col);
    }
}

#$grid.TEXT-print;
$grid.ANSI-print;
#$grid.html-print;


#ddt $grid;

=finish
