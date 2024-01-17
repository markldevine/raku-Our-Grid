#!/usr/bin/env raku

use lib '/home/mdevine/github.com/raku-Our-Grid/lib';

use Our::Phrase;
use Our::Cell;

my Our::Cell $c;
#$c .= new(:text('init via the :text convenience attribute'), :20width, :5x, :7y, :bold);
#$c .= new(:phrases((Our::Phrase.new(:text('init our own Phrase seq'), :blink))));

my @phrases;
@phrases.push: Our::Phrase.new(:text('1st '),                   :bold);
@phrases.push: Our::Phrase.new(:text('2nd '),                   :faint);
@phrases.push: Our::Phrase.new(:text('3rd '),                   :italic);
@phrases.push: Our::Phrase.new(:text('4th '),                   :foreground(blue), :underline);
@phrases.push: Our::Phrase.new(:text('5th '),                   :blink);
@phrases.push: Our::Phrase.new(:text('6th '),                   :reverse);
@phrases.push: Our::Phrase.new(:text('7th '),                   :hide);
@phrases.push: Our::Phrase.new(:text('8th '),                   :strikethrough);
@phrases.push: Our::Phrase.new(:text('9th '),                   :doubleunderline);
@phrases.push: Our::Phrase.new(:text('10'),                     :superscript);
@phrases.push: Our::Phrase.new(:text('th '));
@phrases.push: Our::Phrase.new(:text('11'),                     :subscript);
@phrases.push: Our::Phrase.new(:text('th '));
@phrases.push: Our::Phrase.new(:text('12th allupper '),         :allupper);
@phrases.push: Our::Phrase.new(:text('13TH ALLLOWER '),         :alllower);
@phrases.push: Our::Phrase.new(:text('title case '),            :titlecase);
@phrases.push: Our::Phrase.new(:text('tITLE cASE lOWER CASE '), :titlecaselowercase);
$c .= new(:@phrases, :35row, :5col);
put $c.text-fmt;
put $c.ANSI-fmt;


=finish
