#!/usr/bin/env raku

use lib '/home/mdevine/github.com/raku-Our-Grid/lib';

use Our::Grid::Cell::Fragment;
use Our::Grid::Cell;
use Our::Utilities;

my Our::Grid::Cell $c;

my @fragments;
@fragments.push: Our::Grid::Cell::Fragment.new(:text('1st'),                    :0spaceafter,   :bold);
@fragments.push: Our::Grid::Cell::Fragment.new(:text('2nd'),                    :0spaceafter,   :faint);
@fragments.push: Our::Grid::Cell::Fragment.new(:text('3rd'),                    :0spaceafter,   :italic);
@fragments.push: Our::Grid::Cell::Fragment.new(:text('4th'),                    :0spaceafter,   :underline);
@fragments.push: Our::Grid::Cell::Fragment.new(:text('5th'),                    :0spaceafter,   :blink);
@fragments.push: Our::Grid::Cell::Fragment.new(:text('6th'),                    :0spaceafter,   :reverse);
@fragments.push: Our::Grid::Cell::Fragment.new(:text('7th'),                    :0spaceafter,   :hide);
@fragments.push: Our::Grid::Cell::Fragment.new(:text('8th'),                    :0spaceafter,   :strikethrough);
@fragments.push: Our::Grid::Cell::Fragment.new(:text('9th'),                    :0spaceafter,   :doubleunderline);
@fragments.push: Our::Grid::Cell::Fragment.new(:text('10'),                     :superscript);
@fragments.push: Our::Grid::Cell::Fragment.new(:text('th'),                     :0spaceafter);
@fragments.push: Our::Grid::Cell::Fragment.new(:text('11'),                     :subscript);
@fragments.push: Our::Grid::Cell::Fragment.new(:text('th'),                     :0spaceafter);
@fragments.push: Our::Grid::Cell::Fragment.new(:text('12th allupper'),          :0spaceafter,   :allupper);
@fragments.push: Our::Grid::Cell::Fragment.new(:text('13TH ALLLOWER'),          :0spaceafter,   :alllower);
@fragments.push: Our::Grid::Cell::Fragment.new(:text('title case'),             :0spaceafter,   :titlecase,             :foreground(blue));
@fragments.push: Our::Grid::Cell::Fragment.new(:text('tITLE cASE lOWER CASE'),  :0spaceafter,   :titlecaselowercase,    :foreground(red));
$c .= new(:@fragments);                                                         put $c.TEXT; put $c.ANSI;
$c .= new(:text('Here is another...'), :foreground(orange));                    put $c.TEXT; put $c.ANSI;
$c .= new(:text('Here is number 3...'), :foreground(blue));                     put $c.TEXT; put $c.ANSI;
$c .= new(:text('Here is number 4...'), :foreground(red));                      put $c.TEXT; put $c.ANSI;
$c .= new(:text('Here is number 5...'), :foreground(yellow));                   put $c.TEXT; put $c.ANSI;
$c .= new(:text('Here is number 6...'), :foreground(white));                    put $c.TEXT; put $c.ANSI;
$c .= new(:text('ANSI twice.........'), :foreground(red));                      put $c.ANSI; $c.ANSI-fmt(:foreground(yellow), :background(red), :italic); put $c.ANSI;

=finish
