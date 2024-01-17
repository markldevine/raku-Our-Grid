#!/usr/bin/env raku

use lib '/home/mdevine/github.com/raku-Our-Grid/lib';

use Data::Dump::Tree;
use Our::Phrase;

my @phrases;
#for 'a', 'b', 'c', 0, 1, 2 -> $char {
for ('a' .. 'z').flat -> $char {
    @phrases.push:  Our::Phrase.new(
                        :text($char x 1),
                        :foreground(white),
#                       :background(yellow),
#                       :bold,
#                       :faint,
                        :italic,
#                       :underline,
#                       :blink,
#                       :reverse,
#                       :hide,
#                       :strikethrough,
#                       :doubleunderline,
#                       :superscript,
#                       :subscript,
#                       :allupper,
#                       :alllower,
#                       :titlecase,
#                       :titlecaselowercase,
                        :1spacebefore,
                        :1spaceafter,
                        :0tabbefore,
                        :0tabafter,
                    );
}
#for 10 .. 19 -> $char {
#    @phrases.push:  Our::Phrase.new(
#                        :text($char x 1),
#                        :foreground(yellow),
#                        :subscript,
#                    );
#}

print '|'; .print for @phrases>>.TEXT-fmt; print "|\n";
print '|'; .print for @phrases>>.ANSI-fmt; print "|\n";

=finish

put $m;

=finish
