unit class Our::Cell:api<1>:auth<Mark Devine (mark@markdevine.com)>;

use Data::Dump::Tree;
use Our::Phrase;

has         $.phrases;
has         $.ANSI          is built;
has         $.text;
has         $.TEXT          is built;
has Int     $.width         = 0;
has uint    $.row;
has uint    $.col;
has         %.options;

submethod BUILD(:$text, :$phrases, :$width, :$row, :$col, *%options) {
    die "Must initialize with either ':text' or ':phrases'" unless $text || $phrases;
    $!text          = $text;
    $!width         = $width with $width;
    $!row           = $row with $row;
    $!col           = $col with $col;
    die "Must send both 'row' & 'col' together" if any($!row.so, $!col.so) && ! all($!row.so, $!col.so);
    %!options       = %options;
    $!phrases       = $phrases with $phrases;
    $!phrases[0]    = Our::Phrase.new(:$!text, |%options) unless $!phrases;
}

submethod TWEAK {
    for $!phrases.list -> $phrase {
        $!TEXT     ~= $phrase.TEXT-fmt;
    }
    $!ANSI          = sprintf("\o33[%d;%dH", $!row, $!col) if $!row || $!col;
    for $!phrases.list -> $phrase {
        $!ANSI     ~= $phrase.ANSI-fmt;
    }
}

=finish
