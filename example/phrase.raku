#!/usr/bin/env raku

use lib '/home/mdevine/github.com/raku-Our-Grid/lib';

use Data::Dump::Tree;
use Our::Phrase;

my @phrases;
for 'a', 'b', 'c', 0, 1, 2 -> $char {
    @phrases.push:  Our::Phrase.new(
                        :text($char x 2),
#                       :foreground(white),
#                       :background(yellow),
#                       :bold,
#                       :faint,
#                       :italic,
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
                    );
}
#for 10 .. 19 -> $char {
#    @phrases.push:  Our::Phrase.new(
#                        :text($char x 1),
#                        :foreground(yellow),
#                        :subscript,
#                    );
#}

.print for @phrases>>.text; print "\n";
.print for @phrases>>.ANSI-fmt; print "\n";

=finish

put $m;

=finish
