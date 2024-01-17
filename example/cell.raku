#!/usr/bin/env raku

use lib '/home/mdevine/github.com/raku-Our-Grid/lib';

use Data::Dump::Tree;
use Our::Phrase;
use Our::Cell;

my Our::Cell $c;
$c .= new(:text('init via the :text convenience attribute'), :20width, :5x, :7y, :bold);
$c .= new(:phrases((Our::Phrase.new(:text('init our own Phrase seq'), :blink))));

=finish
