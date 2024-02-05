unit class Our::Grid::Cell:api<1>:auth<Mark Devine (mark@markdevine.com)>;

use Our::Grid::Cell::Fragment;
use Our::Utilities;

use Data::Dump::Tree;

enum Justification is export ( 
    justify-left    => 1, 
    justify-center  => 2, 
    justify-right   => 3, 
);

has                 $.fragments;
has                 %!fragment-options;
has                 $.text;
has                 $.ANSI                  is built(False);
has                 $.TEXT                  is built(False);
has Justification   $.justification         is rw               = justify-left;
has Int             $.visibility            is rw               = 100;              # % of mandatory visibility upon display
has ANSI-Colors     $.highlight             is rw; 
has Int             $.width                                     = 0;
has Int             $!spacebefore                               = 0;
has Int             $!spaceafter                                = 0;
has Str             $!ANSI-spacebefore-pad                      = '';
has Str             $!ANSI-spaceafter-pad                       = '';

submethod BUILD(:$text,
                :$fragments,
                :$row,
                :$col,
                :$highlight,
                :$justification,
                :$width,
                *%fragment-options,
               ) {
    die "Must initialize with either ':text' or ':fragments'" unless any($text.so, $fragments.so) && !all($text.so, $fragments.so);
    $!text              = $text;
    $!width             = $width                with $width;
    %!fragment-options  = %fragment-options     with %fragment-options;
    if $highlight {
        $!highlight         = $highlight;
        %fragment-options<highlight> = $!highlight;
    }
    $!justification     = $justification        with $justification;
    if $fragments {
        $!fragments     = $fragments;
    }
    else {
        $!fragments[0]  = Our::Grid::Cell::Fragment.new(:$!text, |%fragment-options);
    }
}

submethod TWEAK {
    $!TEXT                  = Nil;
    my $i;
    loop ($i = 0; $i < $!fragments.elems; $i++ ) {
        $!TEXT             ~= ' ' x $!fragments[$i].spacebefore unless $i == 0;
        $!TEXT             ~= $!fragments[$i].TEXT;
        $!TEXT             ~= ' ' x $!fragments[$i].spaceafter  unless $i == ($!fragments.elems - 1);
    }
    self.ANSI-fmt;
#   $!ANSI                  = Nil;
#   %!fragment-options<highlight> = $!highlight if $!highlight;
#   loop ($i = 0; $i < $!fragments.elems; $i++ ) {
#       $!ANSI             ~= ' ' x $!fragments[$i].spacebefore unless $i == 0;
#       $!ANSI             ~= $!fragments[$i].ANSI-fmt(|%!fragment-options);
#       $!ANSI             ~= ' ' x $!fragments[$i].spaceafter  unless $i == ($!fragments.elems - 1);
#   }
}

method !calculate-pads (Int:D $width!) {
    my $text-chars      = $!TEXT.Str.chars;
    die 'Unable to fit all data into a ' ~ $width ~ ' character-wide cell!' if $width < $text-chars;
    if $width != $text-chars {
        if $!justification ~~ justify-left {
            $!spaceafter = ($width - $text-chars);
        }
        elsif $!justification ~~ justify-center {
            $!spacebefore = ($width - $text-chars) div 2;
            $!spaceafter = $width - $text-chars - $!spacebefore;
        }
        elsif $!justification ~~ justify-right {
            $!spacebefore = ($width - $text-chars);
        }
    }
}

method TEXT-padded (*%opts) {
    $!width                 = %opts<width> if %opts<width>:exists;
    self!calculate-pads($!width) if $!width;
    return sprintf "%s%s%s", ' ' x $!spacebefore ~ $!TEXT ~ ' ' x $!spaceafter;
}

method ANSI-fmt (*%opts) {
    $!ANSI                  = Nil;
    loop (my $i = 0; $i < $!fragments.elems; $i++ ) {
        $!ANSI             ~= ' ' x $!fragments[$i].spacebefore unless $i == 0;
        $!ANSI             ~= $!fragments[$i].ANSI-fmt(|%opts);
        $!ANSI             ~= ' ' x $!fragments[$i].spaceafter  unless $i == ($!fragments.elems - 1);
    }
    $!ANSI;
}

method ANSI-padded (*%opts) {
    if %opts<width>:exists {
        $!width             = %opts<width>;
        %opts<width>:delete;
    }
    if %opts<justification>:exists {
        $!justification     = %opts<justification>;
        %opts<justification>:delete;
    }
    self.ANSI-fmt(|%opts)   if %opts.elems;
    self!calculate-pads($!width) if $!width;
    $!ANSI-spacebefore-pad  = ' ' x $!spacebefore       if $!spacebefore;
    $!ANSI-spaceafter-pad   = ' ' x $!spaceafter        if $!spaceafter;
    if $!highlight {
        $!ANSI-spacebefore-pad  = "\o33[48;5;" ~ $!highlight.value ~ 'm' ~ $!ANSI-spacebefore-pad ~ "\o33[49m" if $!spacebefore;
        $!ANSI-spaceafter-pad   = "\o33[48;5;" ~ $!highlight.value ~ 'm' ~ $!ANSI-spaceafter-pad  ~ "\o33[49m" if $!spaceafter;
    }
    return $!ANSI-spacebefore-pad ~ $!ANSI ~ $!ANSI-spaceafter-pad;
}

=finish
