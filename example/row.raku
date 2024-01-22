#!/usr/bin/env raku

use lib '/home/mdevine/github.com/raku-Our-Grid/lib';

use Our::Grid::Row;
use Our::Grid::Cell;
use Our::Grid::Cell::Fragment;
use Our::Utilities;

my Our::Grid::Row $r .= new;

my @fragments;
@fragments.push: Our::Grid::Cell::Fragment.new(:text('1st'),                    :1spaceafter,   :bold);
@fragments.push: Our::Grid::Cell::Fragment.new(:text('2nd'),                    :1spaceafter,   :faint);
@fragments.push: Our::Grid::Cell::Fragment.new(:text('3rd'),                    :1spaceafter,   :italic);
@fragments.push: Our::Grid::Cell::Fragment.new(:text('4th'),                    :1spaceafter,   :foreground(blue),      :underline);
@fragments.push: Our::Grid::Cell::Fragment.new(:text('5th'),                    :1spaceafter,   :blink);
@fragments.push: Our::Grid::Cell::Fragment.new(:text('6th'),                    :1spaceafter,   :reverse);
@fragments.push: Our::Grid::Cell::Fragment.new(:text('7th'),                    :1spaceafter,   :hide);
@fragments.push: Our::Grid::Cell::Fragment.new(:text('8th'),                    :1spaceafter,   :strikethrough);
@fragments.push: Our::Grid::Cell::Fragment.new(:text('9th'),                    :1spaceafter,   :doubleunderline);
@fragments.push: Our::Grid::Cell::Fragment.new(:text('10'),                     :superscript);
@fragments.push: Our::Grid::Cell::Fragment.new(:text('th'),                     :1spaceafter);
@fragments.push: Our::Grid::Cell::Fragment.new(:text('11'),                     :subscript);
@fragments.push: Our::Grid::Cell::Fragment.new(:text('th'),                     :1spaceafter);
@fragments.push: Our::Grid::Cell::Fragment.new(:text('12th allupper'),          :1spaceafter,   :allupper);
@fragments.push: Our::Grid::Cell::Fragment.new(:text('13TH ALLLOWER'),          :1spaceafter,   :alllower);
@fragments.push: Our::Grid::Cell::Fragment.new(:text('title case'),             :1spaceafter,   :titlecase,             :foreground(blue));
@fragments.push: Our::Grid::Cell::Fragment.new(:text('tITLE cASE lOWER CASE'),  :1spaceafter,   :titlecaselowercase,    :foreground(red));

$r.add-cell(Our::Grid::Cell.new(:@fragments));
$r.add-cell(Our::Grid::Cell.new(:text('Here is another...'),    :foreground(orange),    :1spacebefore, :1spaceafter));
$r.add-cell(Our::Grid::Cell.new(:text('Here is number 3...'),   :foreground(blue),      :1spacebefore, :1spaceafter));
$r.add-cell(Our::Grid::Cell.new(:text('Here is number 4...'),   :foreground(red),       :1spacebefore, :1spaceafter));
$r.add-cell(Our::Grid::Cell.new(:text('Here is number 5...'),   :foreground(yellow),    :1spacebefore, :1spaceafter));
$r.add-cell(Our::Grid::Cell.new(:text('Here is number 6...'),   :foreground(white),     :1spacebefore, :1spaceafter));

put $r.TEXT-fmt;
put $r.ANSI-fmt;
put "";
put $r.ANSI-fmt(:background(gray244));
put $r.ANSI-fmt(:background(gray248));

=finish
