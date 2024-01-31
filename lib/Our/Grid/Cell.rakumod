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
has                 $.text;
has                 $.ANSI                  is built(False);
has                 $.TEXT                  is built(False);
has Justification   $.justification         is rw               = justify-left;
has Int             $.visibility            is rw               = 100;              # % of mandatory visibility upon display

    Deal with $!highlight (from Our::Grid::Rows)

has ANSI-Colors     $.highlight             is rw; 
has Int             $.width                                     = 0;
has Int             $!spacebefore                               = 0;
has Int             $!spaceafter                                = 0;
has Str             $!ANSI-spacebefore-pad                      = '';
has Str             $!ANSI-spaceafter-pad                       = '';
#as                 %.options;
has Int             $.text-length                               = 0;

submethod BUILD(:$text,
                :$fragments,
                :$row,
                :$col,
                :$justification,
                :$width,
                *%fragment-options,
               ) {
    die "Must initialize with either ':text' or ':fragments'" unless any($text.so, $fragments.so) && !all($text.so, $fragments.so);
    $!text              = $text;
    $!width             = $width                                                        with $width;
    $!justification     = $justification                                                with $justification;
#   %!options           = %options;
    if $fragments {
        $!fragments     = $fragments;
    }
    else {
        $!fragments[0]  = Our::Grid::Cell::Fragment.new(:$!text, |%fragment-options);
    }
}

submethod TWEAK {
    self.TEXT-fmt();
    self.ANSI-fmt();
}

method TEXT-fmt {
    $!width                 = %opts<width> if %opts<width>:exists;
    $!TEXT                  = Nil;
    my $text-chars;
    for $!fragments.list -> $fragment {
        $text-chars         = $fragment.text.Str.chars + $fragment.spacebefore + $fragment.spaceafter;
    }
    $text-chars            -= ($!fragments[0].spacebefore + $!fragments[*-1].spaceafter);

    if $!width {
        die 'Unable to fit all data into a ' ~ $!width ~ ' character-wide cell!' if $!width < $text-chars;
        if $!width != $text-chars {
            if $!justification ~~ justify-left {
                $!spaceafter = ($!width - $text-chars);
            }
            elsif $!justification ~~ justify-center {
                $!spacebefore = ($!width - $text-chars) div 2;
                $!spaceafter = $!width - $text-chars - $!spacebefore;
            }
            elsif $!justification ~~ justify-right {
                $!spacebefore = ($!width - $text-chars);
            }
        }
    }
    $!TEXT                  = Nil;
    loop (my $i = 0; $i < $!fragments.elems; $i++ ) {
        if $i == 0 {
            $!TEXT         ~= $!fragments[$i].TEXT-fmt(|%opts_first);
        }
        elsif $i == ($!fragments.elems - 1) {
            $!TEXT         ~= $!fragments[$i].TEXT-fmt(|%opts_last);
        }
        else {
            $!TEXT         ~= $!fragments[$i].TEXT-fmt(|%opts);
        }
    }
    $!text-length          = $!TEXT.Str.chars + $!spacebefore + $!spaceafter;
    $!TEXT;
}

#method TEXT-fmt (*%opts) {
#    $!width                 = %opts<width> if %opts<width>:exists;
#    $!TEXT                  = Nil;
#    my $text-chars;
#    for $!fragments.list -> $fragment {
#        $text-chars         = $fragment.text.Str.chars + $fragment.spacebefore + $fragment.spaceafter;
#    }
#    $text-chars            -= ($!fragments[0].spacebefore + $!fragments[*-1].spaceafter);
#
#    die 'Unable to fit all data into a ' ~ $!width ~ ' character-wide cell!' if $!width && $!width < $text-chars;
#    if $!width {
#        if $!width != $text-chars {
#            if $!justification ~~ justify-left {
#                $!fragments[*-1].cell-spaceafter = ($!width - $text-chars);
#            }
#            elsif $!justification ~~ justify-center {
#                $!fragments[0].cell-spacebefore = ($!width - $text-chars) div 2;
#                $!fragments[*-1].cell-spaceafter = $!width - $text-chars - $!fragments[0].cell-spacebefore;
#            }
#            elsif $!justification ~~ justify-right {
#                $!fragments[0].cell-spacebefore = ($!width - $text-chars);
#            }
#        }
#    }
#    $!TEXT                  = Nil;
##   Don't let any %options alter the first fragment's :spacebefore or the last fragment's :spaceafter
#    my %opts_first          = %opts;
#    %opts_first<spacebefore>:delete;
#    my %opts_last           = %opts;
#    %opts_last<spaceafter>:delete;
#    loop (my $i = 0; $i < $!fragments.elems; $i++ ) {
#        if $i == 0 {
#            $!TEXT         ~= $!fragments[$i].TEXT-fmt(|%opts_first);
#        }
#        elsif $i == ($!fragments.elems - 1) {
#            $!TEXT         ~= $!fragments[$i].TEXT-fmt(|%opts_last);
#        }
#        else {
#            $!TEXT         ~= $!fragments[$i].TEXT-fmt(|%opts);
#        }
#    }
#    $!text-length          = $!TEXT.Str.chars + $!spacebefore + $!spaceafter;
#    $!TEXT;
#}

method ANSI-fmt (*%opts) {
    $!width                 = %opts<width> if %opts<width>:exists;
    $!ANSI                  = Nil;
    for $!fragments.list -> $fragment {
        $!ANSI             ~= $fragment.ANSI-fmt(|%opts);
    }
}

=finish
