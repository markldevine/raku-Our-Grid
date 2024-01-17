#!/usr/bin/env raku

use lib '/home/mdevine/github.com/raku-Our-Grid/lib';

use Our::Phrase;
use Our::Cell;

my Our::Cell $c;

my @phrases;
@phrases.push: Our::Phrase.new(:text('1st'),                    :1spaceafter,   :bold);
@phrases.push: Our::Phrase.new(:text('2nd'),                    :1spaceafter,   :faint);
@phrases.push: Our::Phrase.new(:text('3rd'),                    :1spaceafter,   :italic);
@phrases.push: Our::Phrase.new(:text('4th'),                    :1spaceafter,   :foreground(blue), :underline);
@phrases.push: Our::Phrase.new(:text('5th'),                    :1spaceafter,   :blink);
@phrases.push: Our::Phrase.new(:text('6th'),                    :1spaceafter,   :reverse);
@phrases.push: Our::Phrase.new(:text('7th'),                    :1spaceafter,   :hide);
@phrases.push: Our::Phrase.new(:text('8th'),                    :1spaceafter,   :strikethrough);
@phrases.push: Our::Phrase.new(:text('9th'),                    :1spaceafter,   :doubleunderline);
@phrases.push: Our::Phrase.new(:text('10'),                     :superscript);
@phrases.push: Our::Phrase.new(:text('th'),                     :1spaceafter);
@phrases.push: Our::Phrase.new(:text('11'),                     :subscript);
@phrases.push: Our::Phrase.new(:text('th'),                     :1spaceafter);
@phrases.push: Our::Phrase.new(:text('12th allupper'),          :1spaceafter,   :allupper);
@phrases.push: Our::Phrase.new(:text('13TH ALLLOWER'),          :1spaceafter,   :alllower);
@phrases.push: Our::Phrase.new(:text('title case'),             :1spaceafter,   :titlecase);
@phrases.push: Our::Phrase.new(:text('tITLE cASE lOWER CASE'),  :1spaceafter,   :titlecaselowercase);
$c .= new(:@phrases, :35row, :5col);

put $c.TEXT;
put $c.ANSI;


=finish
