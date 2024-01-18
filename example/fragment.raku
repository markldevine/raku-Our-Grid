#!/usr/bin/env raku

use lib '/home/mdevine/github.com/raku-Our-Grid/lib';

use Data::Dump::Tree;
use Our::Grid::Cell::Fragment;

my @fragments;
#for 'a', 'b', 'c', 0, 1, 2 -> $char {
for ('a' .. 'e').flat -> $char {
    @fragments.push:    Our::Grid::Cell::Fragment.new(
                            :text($char x 2),
                            :foreground(white),
#                           :background(yellow),
#                           :bold,
#                           :faint,
                            :italic,
#                           :underline,
#                           :blink,
#                           :reverse,
#                           :hide,
#                           :strikethrough,
#                           :doubleunderline,
#                           :superscript,
#                           :subscript,
#                           :allupper,
#                           :alllower,
#                           :titlecase,
#                           :titlecaselowercase,
                            :1spacebefore,
                            :0spaceafter,
                            :0tabbefore,
                            :0tabafter,
                        );
}
#for 10 .. 19 -> $char {
#    @fragments.push:   Our::Grid::Cell::Fragment.new(
#                           :text($char x 1),
#                           :foreground(yellow),
#                           :subscript,
#                       );
#}

print '|'; .print for @fragments>>.TEXT; print "|\n";
print '|'; .print for @fragments>>.ANSI-fmt; print "|\n";

=finish
