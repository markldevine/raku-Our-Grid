#!/usr/bin/env raku

use lib '/home/mdevine/github.com/raku-Our-Grid/lib';

use Our::Phrase;
use Our::Cell;

my Our::Cell $c;

my @phrases;
@phrases.push: Our::Phrase.new(:text('1st'),                    :spaceafter,    :bold);
@phrases.push: Our::Phrase.new(:text('2nd'),                    :spaceafter,    :faint);
@phrases.push: Our::Phrase.new(:text('3rd'),                    :spaceafter,    :italic);
@phrases.push: Our::Phrase.new(:text('4th'),                    :spaceafter,    :foreground(blue), :underline);
@phrases.push: Our::Phrase.new(:text('5th'),                    :spaceafter,    :blink);
@phrases.push: Our::Phrase.new(:text('6th'),                    :spaceafter,    :reverse);
@phrases.push: Our::Phrase.new(:text('7th'),                    :spaceafter,    :hide);
@phrases.push: Our::Phrase.new(:text('8th'),                    :spaceafter,    :strikethrough);
@phrases.push: Our::Phrase.new(:text('9th'),                    :spaceafter,    :doubleunderline);
@phrases.push: Our::Phrase.new(:text('10'),                     :superscript);
@phrases.push: Our::Phrase.new(:text('th'),                     :spaceafter);
@phrases.push: Our::Phrase.new(:text('11'),                     :spaceafter,    :subscript);
@phrases.push: Our::Phrase.new(:text('th'));
@phrases.push: Our::Phrase.new(:text('12th allupper'),          :spaceafter,    :allupper);
@phrases.push: Our::Phrase.new(:text('13TH ALLLOWER'),          :spaceafter,    :alllower);
@phrases.push: Our::Phrase.new(:text('title case'),             :spaceafter,    :titlecase);
@phrases.push: Our::Phrase.new(:text('tITLE cASE lOWER CASE'),  :spaceafter,    :titlecaselowercase);
$c .= new(:@phrases, :35row, :5col);
put $c.text;
put $c.ANSI;


=finish
