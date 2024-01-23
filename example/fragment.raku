#!/usr/bin/env raku

use lib '/home/mdevine/github.com/raku-Our-Grid/lib';
use lib '/home/mdevine/github.com/raku-Our-Utilities/lib';

use Our::Grid::Cell::Fragment;
use Our::Utilities;

my @fragments;
#for ('a' .. 'e').flat -> $char {
#    @fragments.push:    Our::Grid::Cell::Fragment.new(
#                            :text($char x 2),
#                            :foreground(black),
#                            :background(gray254),
##                           :bold,
##                           :faint,
#                            :italic,
##                           :underline,
##                           :blink,
##                           :reverse,
##                           :hide,
##                           :strikethrough,
##                           :doubleunderline,
##                           :superscript,
##                           :subscript,
##                           :allupper,
##                           :alllower,
##                           :titlecase,
##                           :titlecaselowercase,
#                            :1spacebefore,
#                            :1spaceafter,
#                        );
#}
#@fragments.push:    Our::Grid::Cell::Fragment.new(
#                        :text('01/23/2024 7:50'),
#                        :foreground(white),
#                        :background(gray244),
#                        :1spaceafter,
#                        :date-time,
#                    );
#@fragments.push:    Our::Grid::Cell::Fragment.new(
#                        :1234567890text,
#                        :foreground(white),
#                        :background(gray244),
#                        :1spaceafter,
#                        :add-commas-to-digits,
#                    );
#@fragments.push:    Our::Grid::Cell::Fragment.new(
#                        :text("-12345.67890"),
#                        :foreground(white),
#                        :background(gray244),
#                        :0spaceafter,
#                        :add-commas-to-digits,
#                    );
#@fragments.push:    Our::Grid::Cell::Fragment.new(
#                        :1234567890text,
#                        :foreground(black),
#                        :background(gray254),
#                        :1spacebefore,
#                        :1spaceafter,
#                        :number-to-metric-unit,
#                    );
#@fragments.push:    Our::Grid::Cell::Fragment.new(
#                        :1234567890text,
#                        :foreground(white),
#                        :background(gray244),
#                        :1spacebefore,
#                        :1spaceafter,
#                        :bytes-to-bytes-unit,
#                    );
#@fragments.push:    Our::Grid::Cell::Fragment.new(
#                        :1234567890text,
#                        :foreground(white),
#                        :background(gray244),
#                        :1spacebefore,
#                        :1spaceafter,
#                        :number-to-metric-unit,
#                    );
#@fragments.push:    Our::Grid::Cell::Fragment.new(
#                        :text('11.111 M'),
#                        :foreground(white),
#                        :background(gray244),
#                        :1spacebefore,
#                        :1spaceafter,
#                        :bytes-unit-to-bytes,
#                    );
#@fragments.push:    Our::Grid::Cell::Fragment.new(
#                        :text('22.222 M'),
#                        :foreground(white),
#                        :background(gray244),
#                        :1spacebefore,
#                        :1spaceafter,
#                        :bytes-unit-to-comma-bytes,
#                    );

print '|'; .print for @fragments>>.TEXT-fmt; print "|\n";
print '|'; .print for @fragments>>.ANSI-fmt; print "|\n";
#print '|'; .print for @fragments>>.ANSI-fmt(:0spacebefore, :0spaceafter); print "|\n";

=finish
