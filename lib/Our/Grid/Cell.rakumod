unit class Our::Grid::Cell:api<1>:auth<Mark Devine (mark@markdevine.com)>;

use Our::Grid::Cell::Fragment;
use Our::Utilities;

enum Justification is export ( 
    justify-left    => 1, 
    justify-center  => 2, 
    justify-right   => 3, 
);

has                 $.fragments;
has                 %!fragment-options;
has                 $.text;
has                 $.ANSI                      is built(False);
has                 $.TEXT                      is built(False);
has Justification   $.justification             is rw               = justify-left;
has Justification   $!previous-justification                        = justify-left;
has Int             $.visibility                is rw               = 100;              # % of mandatory visibility upon display
has ANSI-Colors     $.highlight                 is rw; 
has Int             $.width                                         = 0;
has Int             $!previous-width                                = 0;
has Int             $!spacebefore                                   = 0;
has Int             $!spaceafter                                    = 0;
has Str             $!ANSI-spacebefore-pad                          = '';
has Str             $!ANSI-spaceafter-pad                           = '';

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
    $!TEXT                      = Nil;
    $!fragments[0].spacebefore  = 0;
    $!fragments[*-1].spaceafter = 0;
    my $i;
    loop ($i = 0; $i < $!fragments.elems; $i++ ) {
        $!TEXT                 ~= ' ' x $!fragments[$i].spacebefore unless $i == 0;
        $!TEXT                 ~= $!fragments[$i].TEXT;
        $!TEXT                 ~= ' ' x $!fragments[$i].spaceafter  unless $i == ($!fragments.elems - 1);
    }
    self.ANSI-fmt;
    return self;
}

method !calculate-pads {
    return 1                    if $!width == $!previous-width && $!justification.value == $!previous-justification.value;
    $!previous-width            = $!width;
    $!previous-justification    = $!justification;
    my $text-chars              = $!TEXT.Str.chars;
    die 'Unable to fit all data into a ' ~ $!width ~ ' character-wide cell!' if $!width < $text-chars;
    if $!width != $text-chars {
        if $!justification ~~ justify-left {
            $!spacebefore       = 0;
            $!spaceafter        = ($!width - $text-chars);
        }
        elsif $!justification ~~ justify-center {
            $!spacebefore       = ($!width - $text-chars) div 2;
            $!spaceafter        = $!width - $text-chars - $!spacebefore;
        }
        elsif $!justification ~~ justify-right {
            $!spacebefore       = ($!width - $text-chars);
            $!spaceafter        = 0;
        }
    }
}

method TEXT-padded (*%opts) {
    $!width                 = %opts<width>          if %opts<width>:exists;
    $!justification         = %opts<justification>  if %opts<justification>:exists;
    self!calculate-pads;
    return ' ' x $!spacebefore ~ $!TEXT ~ ' ' x $!spaceafter;
}

method ANSI-fmt (*%opts) {
    if %opts<width>:exists {
        $!width             = %opts<width> // 0;
#       %opts<width>:delete;
    }
#   $!width               //= 0;
    if %opts<justification>:exists {
        $!justification     = %opts<justification>;
#       %opts<justification>:delete;
    }
    self!calculate-pads     if $!width;
    $!ANSI-spacebefore-pad  = '';
    $!ANSI-spacebefore-pad  = ' ' x $!spacebefore       if $!spacebefore;
    $!ANSI-spaceafter-pad   = '';
    $!ANSI-spaceafter-pad   = ' ' x $!spaceafter        if $!spaceafter;
    if $!highlight {
        $!ANSI-spacebefore-pad  = "\o33[48;5;" ~ $!highlight.value ~ 'm' ~ $!ANSI-spacebefore-pad ~ "\o33[49m" if $!spacebefore;
        $!ANSI-spaceafter-pad   = "\o33[48;5;" ~ $!highlight.value ~ 'm' ~ $!ANSI-spaceafter-pad  ~ "\o33[49m" if $!spaceafter;
    }
    $!ANSI                  = Nil;
    loop (my $i = 0; $i < $!fragments.elems; $i++ ) {
        $!ANSI             ~= $!fragments[$i].ANSI-spacebefore-pad unless $i == 0;
        if %opts.elems {
            $!ANSI         ~= $!fragments[$i].ANSI-fmt(|%opts);
        }
        else {
            $!ANSI         ~= $!fragments[$i].ANSI;
        }
        $!ANSI             ~= $!fragments[$i].ANSI-spaceafter-pad  unless $i == ($!fragments.elems - 1);
    }
    return self;
}

method ANSI-padded {
    return $!ANSI-spacebefore-pad ~ $!ANSI ~ $!ANSI-spaceafter-pad;
}

=finish
