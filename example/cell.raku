#!/usr/bin/env raku

use lib '/home/mdevine/github.com/raku-Our-Grid/lib';

use Our::Grid::Cell::Fragment;
use Our::Grid::Cell;
use Our::Utilities;
use Data::Dump::Tree;

my Our::Grid::Cell $c;

#$c .= new(:text(' 12345     '), :trim-input(True), :foreground(yellow), :highlight(gray244), :18width, :justification(justify-left),); put '|' ~ $c.ANSI-padded ~ '|';
#$c .= new(:text(' 12345     '), :trim-input(True), :foreground(yellow), :background(black) :highlight(gray244), :18width, :justification(justify-left),); put '|' ~ $c.ANSI-padded ~ '|';
#$c .= new(:text('12345 '), :allupper, :foreground(yellow), :background(black) :highlight(gray244), :18width, :justification(justify-center),); put '|' ~ $c.ANSI-padded ~ '|';
#$c .= new(:text('12345'), :allupper, :foreground(yellow), :background(black) :highlight(gray244), :18width, :justification(justify-right),); put '|' ~ $c.ANSI-padded ~ '|';

my @fragments;
@fragments.push: Our::Grid::Cell::Fragment.new(:text('1st'),                    :1spaceafter,   :bold);
@fragments.push: Our::Grid::Cell::Fragment.new(:text('2nd'),                    :1spaceafter,   :faint);
#@fragments.push: Our::Grid::Cell::Fragment.new(:text('3rd'),                    :1spaceafter,   :italic);
#@fragments.push: Our::Grid::Cell::Fragment.new(:text('4th'),                    :1spaceafter,   :underline);
#@fragments.push: Our::Grid::Cell::Fragment.new(:text('5th'),                    :1spaceafter,   :blink);
#@fragments.push: Our::Grid::Cell::Fragment.new(:text('6th'),                    :1spaceafter,   :reverse);
#@fragments.push: Our::Grid::Cell::Fragment.new(:text('7th'),                    :1spaceafter,   :hide);
#@fragments.push: Our::Grid::Cell::Fragment.new(:text('8th'),                    :1spaceafter,   :strikethrough);
#@fragments.push: Our::Grid::Cell::Fragment.new(:text('9th'),                    :1spaceafter,   :doubleunderline);
#@fragments.push: Our::Grid::Cell::Fragment.new(:text('10'),                     :superscript);
#@fragments.push: Our::Grid::Cell::Fragment.new(:text('th'),                     :1spaceafter);
#@fragments.push: Our::Grid::Cell::Fragment.new(:text('11'),                     :subscript);
#@fragments.push: Our::Grid::Cell::Fragment.new(:text('th'),                     :1spaceafter);
#@fragments.push: Our::Grid::Cell::Fragment.new(:text('12th allupper'),          :1spaceafter,   :allupper);
#@fragments.push: Our::Grid::Cell::Fragment.new(:text('13TH ALLLOWER'),          :1spaceafter,   :alllower);
#@fragments.push: Our::Grid::Cell::Fragment.new(:text('title case'),             :1spaceafter,   :titlecase,             :foreground(blue));
#@fragments.push: Our::Grid::Cell::Fragment.new(:text('tITLE cASE lOWER CASE'),  :1spaceafter,   :titlecaselowercase,    :foreground(red));
$c .= new(:@fragments);                                                         put $c.TEXT; put '|' ~ $c.ANSI-padded(:highlight(gray254), :13width, :justification(justify-center)) ~ '|';

=finish

$c .= new(:text('Here is number 1...'), :foreground(orange));                   put '|' ~ $c.TEXT ~ '|'; put $c.ANSI-padded;
$c .= new(:text('Here is number 2...'), :foreground(blue));                     put '|' ~ $c.TEXT ~ '|'; put $c.ANSI-padded;
$c .= new(:text('Here is number 3...'), :foreground(red));                      put '|' ~ $c.TEXT ~ '|'; put $c.ANSI-padded;
$c .= new(:text('Here is number 4...'), :foreground(yellow));                   put '|' ~ $c.TEXT ~ '|'; put $c.ANSI-padded;
$c .= new(:text('Here is number 5...'), :foreground(white));                    put '|' ~ $c.TEXT ~ '|'; put $c.ANSI-padded;
$c .= new(:text('ANSI twice.........'), :foreground(red));                      put $c.ANSI-padded; put $c.ANSI-padded(:foreground(yellow), :background(red), :italic);

