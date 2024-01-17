unit class Our::Cell:api<1>:auth<Mark Devine (mark@markdevine.com)>;

use Data::Dump::Tree;
use Our::Phrase;

has         $.phrases;
has         $.text;
has Int     $.width         = 0;
has Int     $.x;
has Int     $.y;
has         %.options;

submethod BUILD(:$text, :$phrases, :$width, :$x, :$y, *%options) {
    die "Must initialize with either ':text' or ':phrases'" unless $text || $phrases;
    $!text          = $text;
    $!width         = $width with $width;
    $!x             = $x with $x;
    $!y             = $y with $y;
    die "Must send both 'x' & 'y' positional coordinates together" if any($!x.so, $!y.so) && ! all($!x.so, $!y.so);
    %!options       = %options;
    $!phrases       = $phrases with $phrases;
    $!phrases[0]    = Our::Phrase.new(:$!text, |%options) unless $!phrases;
}

submethod TWEAK {
ddt self;
}

method text-print {
    .print for $!phrases>>.text;
    print "\n";
}

method ANSI-print {
    .print for $!phrases>>.ANSI-fmt;
    print "\n";
}

=finish
