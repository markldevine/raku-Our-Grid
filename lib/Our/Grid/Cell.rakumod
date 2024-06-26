unit class Our::Grid::Cell:api<1>:auth<Mark Devine (mark@markdevine.com)>;

use Color::Names:api<2>;
use Our::Grid::Cell::Fragment;
use Our::Utilities;

has                 $.fragments;
has                 %!fragment-options;
has                 $.text;
has                 $.ANSI                      is built(False);
has                 $.TEXT                      is built(False);
my  subset          Justification               where * (elem) $Justification;
has Justification   $.justification             is rw               = 'left';
has Justification   $!previous-justification                        = 'left';

has Int             $.visibility                is rw               = 100;              # % of mandatory visibility upon display
has Any             $.highlight                 is rw; 
has Int             $.width                                         = 0;
has Int             $!previous-width                                = 0;
has Int             $!spacebefore                                   = 0;
has Int             $!spaceafter                                    = 0;
has                 $.supplemental-data;                                                # additional information for interfaces with the capability
has Str             $!ANSI-spacebefore-pad                          = '';
has Str             $!ANSI-spaceafter-pad                           = '';

my  subset          Sort-Type                   where * (elem) $Sort-Type;
has Sort-Type       $.cell-sort-type;
has Str             $.cell-sort-string-portion;
has Int             $.cell-sort-digits-portion;

submethod BUILD(:$text,
                :$fragments,
                :$row,
                :$col,
                :$highlight,
                :$justification,
                :$width,
                *%fragment-options,
               ) {
#   die "Must initialize with either ':text' or ':fragments'" unless any($text.so, $fragments.so) && !all($text.so, $fragments.so);
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
    elsif $!text {
        $!fragments[0]  = Our::Grid::Cell::Fragment.new(:$!text, |%fragment-options);
    }
    else {
        $!fragments[0]  = Our::Grid::Cell::Fragment.new(:text(''), |%fragment-options);
    }
}

submethod TWEAK {
    $!text                      = '';
    $!TEXT                      = '';
    loop (my $i = 0; $i < $!fragments.elems; $i++ ) {

        $!text                 ~= ' ' x $!fragments[$i].spacebefore unless $i == 0;
        $!text                 ~= $!fragments[$i].text;
        $!text                 ~= ' ' x $!fragments[$i].spaceafter  unless $i == ($!fragments.elems - 1);

        $!TEXT                 ~= ' ' x $!fragments[$i].spacebefore;
        $!TEXT                 ~= $!fragments[$i].TEXT;
        $!TEXT                 ~= ' ' x $!fragments[$i].spaceafter;
    }
    given $!text {
        when /^ \s* \d+ \s* $/          { $!cell-sort-type = 'digits';  }
        when /^ \s* (\D+) (\d+) \s* $/  {
            $!cell-sort-string-portion  = $0.Str;
            $!cell-sort-digits-portion  = $1.Int;
            $!cell-sort-type            = 'string-digits';
        }
        when /^ \s* (\d+) (\D+) \s* $/  {
            $!cell-sort-digits-portion  = $0.Int;
            $!cell-sort-string-portion  = $1.Str;
            $!cell-sort-type            = 'digits-string';
        }
        default                         { $!cell-sort-type = 'string';  }
    }
    self.ANSI-fmt;
    return self;
}

method !calculate-pads {
    return 1                    if $!width == $!previous-width && $!justification eq $!previous-justification;
    $!previous-width            = $!width;
    $!previous-justification    = $!justification;
    my $text-chars              = $!TEXT.Str.chars;

    die 'Unable to fit all data into a ' ~ $!width ~ ' character-wide cell!' if $!width < $text-chars;
    if $!width != $text-chars {
        given $!justification {
            when 'left'     {
                $!spacebefore       = 0;
                $!spaceafter        = ($!width - $text-chars);
            }
            when 'center'   {
                $!spacebefore       = ($!width - $text-chars) div 2;
                $!spaceafter        = $!width - $text-chars - $!spacebefore;
            }
            when 'right'    {
                $!spacebefore       = ($!width - $text-chars);
                $!spaceafter        = 0;
            }
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
    }
    if %opts<justification>:exists {
        $!justification     = %opts<justification>;
    }
    self!calculate-pads     if $!width;
    $!ANSI-spacebefore-pad  = '';
    $!ANSI-spacebefore-pad  = ' ' x $!spacebefore       if $!spacebefore;
    $!ANSI-spaceafter-pad   = '';
    $!ANSI-spaceafter-pad   = ' ' x $!spaceafter        if $!spaceafter;
    my $highlight-rgb;
    if $!highlight {
        if $!highlight ~~ Positional {
            if $!highlight.elems == 3 {
                $highlight-rgb = $!highlight;
            }
            else {
                note;
            }
        }
        else {
            $highlight-rgb = Color::Names.color-data(<CSS3>).&find-color($!highlight, :exact).values.first<rgb>;
        }

        if $highlight-rgb {
            if $!spacebefore {
                $!ANSI-spacebefore-pad  = "\o33[48;2;"
                                        ~ $highlight-rgb[0] ~ ';'
                                        ~ $highlight-rgb[1] ~ ';'
                                        ~ $highlight-rgb[2]
                                        ~ 'm'
                                        ~ $!ANSI-spacebefore-pad
                                        ~ "\o33[49m";
            }
            if $!spaceafter {
                $!ANSI-spaceafter-pad   = "\o33[48;2;"
                                        ~ $highlight-rgb[0] ~ ';'
                                        ~ $highlight-rgb[1] ~ ';'
                                        ~ $highlight-rgb[2]
                                        ~ 'm'
                                        ~ $!ANSI-spaceafter-pad
                                        ~ "\o33[49m";
            }
        }
    }
    $!ANSI                  = Nil;
    loop (my $i = 0; $i < $!fragments.elems; $i++ ) {

        $!ANSI             ~= $!fragments[$i].ANSI-spacebefore-pad;
        if %opts.elems {
            $!ANSI         ~= $!fragments[$i].ANSI-fmt(|%opts);
        }
        else {
            $!ANSI         ~= $!fragments[$i].ANSI;
        }

        $!ANSI             ~= $!fragments[$i].ANSI-spaceafter-pad;
    }
    return self;
}

method ANSI-padded {
    return $!ANSI-spacebefore-pad ~ $!ANSI ~ $!ANSI-spaceafter-pad;
}

=finish
