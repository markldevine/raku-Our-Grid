#!/usr/bin/env raku

use lib '/home/mdevine/github.com/raku-Our-Grid/lib';

use Our::Phrase;
use Our::Cell;

my Our::Cell $c;
#$c .= new(:text('init via the :text convenience attribute'), :20width, :5x, :7y, :bold);
#$c .= new(:phrases((Our::Phrase.new(:text('init our own Phrase seq'), :blink))));

my Our::Phrase $p1 .= new(:text('1st part '), :italic);
my Our::Phrase $p2 .= new(:text('2nd part'), :reverse);
$c .= new(:phrases($p1, $p2));
$c.text-print;
$c.ANSI-print;


=finish
