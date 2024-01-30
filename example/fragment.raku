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
#                        :text('2024/1/31 07:05:05'),
#                        :foreground(white),
#                        :background(gray244),
#                        :1spacebefore,
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
#                        :text("+ 1234567890"),
#                        :foreground(white),
#                        :background(gray244),
#                        :1spaceafter,
#                        :add-commas-to-digits,
#                    );
#@fragments.push:    Our::Grid::Cell::Fragment.new(
#                        :text(" + 12345.67890"),
#                        :foreground(white),
#                        :background(gray244),
#                        :1spacebefore,
#                        :1spaceafter,
#                        :add-commas-to-digits,
#                    );
#@fragments.push:    Our::Grid::Cell::Fragment.new(
#                        :1234567890text,
#                        :foreground(white),
#                        :background(gray244),
#                        :1spacebefore,
#                        :1spaceafter,
#                        :bytes-to-bytes-unit,
#                    );
@fragments.push:    Our::Grid::Cell::Fragment.new(
                        :text('11.111 M'),
                        :foreground(white),
                        :background(gray244),
                        :1spacebefore,
                        :1spaceafter,
                        :bytes-unit-to-bytes,
                    );
@fragments.push:    Our::Grid::Cell::Fragment.new(
                        :text('11.111 M'),
                        :foreground(white),
                        :background(gray244),
                        :1spacebefore,
                        :1spaceafter,
                        :bytes-unit-to-comma-bytes,
                    );
@fragments.push:    Our::Grid::Cell::Fragment.new(
                        :text('11.111 M'),
                        :foreground(white),
                        :background(gray244),
                        :1spacebefore,
                        :1spaceafter,
                        :bytes-unit-to-round-bytes,
                    );
@fragments.push:    Our::Grid::Cell::Fragment.new(
                        :text('11.111 M'),
                        :foreground(white),
                        :background(gray244),
                        :1spacebefore,
                        :1spaceafter,
                        :bytes-unit-to-comma-round-bytes,
                    );
#@fragments.push:    Our::Grid::Cell::Fragment.new(
#                        :text(22222.2),
#                        :foreground(black),
#                        :background(gray254),
#                        :1spacebefore,
#                        :1spaceafter,
#                        :number-to-metric-unit,
#                    );
#@fragments.push:    Our::Grid::Cell::Fragment.new(
#                        :text('22.2222 K'),
#                        :foreground(black),
#                        :background(gray254),
#                        :1spacebefore,
#                        :1spaceafter,
#                        :metric-unit-to-number,
#                    );
#@fragments.push:    Our::Grid::Cell::Fragment.new(
#                        :text('22.2222 K'),
#                        :foreground(black),
#                        :background(gray254),
#                        :1spacebefore,
#                        :1spaceafter,
#                        :metric-unit-to-comma-number,
#                    );

print '|'; .print for @fragments>>.TEXT-padded; print "|\n";
print '|'; .print for @fragments>>.ANSI-padded; print "|\n";

for ^5 {
    for @fragments -> $fragment {
        print '|';
        $fragment.ANSI-fmt(:foreground(black), :background(gray254), :highlight(blue));
        print $fragment.ANSI-padded;
        $fragment.ANSI-fmt(:foreground(white), :background(gray244), :highlight(red));
        print $fragment.ANSI-padded;
        print "|\n";
    }
}

=finish
