#!/usr/bin/env raku

use lib '/home/mdevine/github.com/raku-Our-Grid/lib';

use Our::Grid::Cell::Fragment;
use Our::Utilities;

my @fragments;
for ('a' .. 'e').flat -> $char {
    @fragments.push:    Our::Grid::Cell::Fragment.new(
                            :text($char x 2),
                            :foreground(black),
                            :background(gray254),
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
                            :1spaceafter,
                        );
}
#for 10 .. 19 -> $char {
#    @fragments.push:   Our::Grid::Cell::Fragment.new(
#                           :text($char x 1),
#                           :foreground(yellow),
#                           :subscript,
#                       );
#}

print '|'; .print for @fragments>>.TEXT-fmt; print "|\n";
print '|'; .print for @fragments>>.ANSI-fmt; print "|\n";
print '|'; .print for @fragments>>.ANSI-fmt(:0spacebefore, :0spaceafter); print "|\n";

=finish
