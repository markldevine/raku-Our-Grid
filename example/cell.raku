#!/usr/bin/env raku

use lib '/home/mdevine/github.com/raku-Our-Grid/lib';

use Our::Phrase;
use Our::Cell;

my Our::Cell $c;

my @phrases;
@phrases.push: Our::Phrase.new(:text('1st'),                    :0spaceafter,   :bold);
@phrases.push: Our::Phrase.new(:text('2nd'),                    :0spaceafter,   :faint);
@phrases.push: Our::Phrase.new(:text('3rd'),                    :0spaceafter,   :italic);
@phrases.push: Our::Phrase.new(:text('4th'),                    :0spaceafter,   :foreground(blue),      :underline);
@phrases.push: Our::Phrase.new(:text('5th'),                    :0spaceafter,   :blink);
@phrases.push: Our::Phrase.new(:text('6th'),                    :0spaceafter,   :reverse);
@phrases.push: Our::Phrase.new(:text('7th'),                    :0spaceafter,   :hide);
@phrases.push: Our::Phrase.new(:text('8th'),                    :0spaceafter,   :strikethrough);
@phrases.push: Our::Phrase.new(:text('9th'),                    :0spaceafter,   :doubleunderline);
@phrases.push: Our::Phrase.new(:text('10'),                     :superscript);
@phrases.push: Our::Phrase.new(:text('th'),                     :0spaceafter);
@phrases.push: Our::Phrase.new(:text('11'),                     :subscript);
@phrases.push: Our::Phrase.new(:text('th'),                     :0spaceafter);
@phrases.push: Our::Phrase.new(:text('12th allupper'),          :0spaceafter,   :allupper);
@phrases.push: Our::Phrase.new(:text('13TH ALLLOWER'),          :0spaceafter,   :alllower);
@phrases.push: Our::Phrase.new(:text('title case'),             :0spaceafter,   :titlecase,             :foreground(blue));
@phrases.push: Our::Phrase.new(:text('tITLE cASE lOWER CASE'),  :0spaceafter,   :titlecaselowercase,    :foreground(red));
$c .= new(:@phrases, :2row, :1col);

put $c.TEXT;
put $c.ANSI;

$c .= new(:text('Here is another...'), :foreground(orange), :3row, :10col).ANSI.put;

=finish
