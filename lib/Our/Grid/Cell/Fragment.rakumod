unit class Our::Grid::Cell::Fragment:api<1>:auth<Mark Devine (mark@markdevine.com)>;

use Color::Names:api<2>;
use Our::Utilities;

has Str     $.foreground                        is rw;
has         $!foreground-rgb;
has Any     $.background                        is rw;
has         $!background-rgb;
has Any     $.highlight                         is rw;
has         $!highlight-rgb;
has Bool    $.bold                              is rw;
has Bool    $.faint                             is rw;
has Bool    $.italic                            is rw;
has Bool    $.underline                         is rw;
has Bool    $.blink                             is rw;
has Bool    $.reverse                           is rw;
has Bool    $.hide                              is rw;
has Bool    $.strikethrough                     is rw;
has Bool    $.doubleunderline                   is rw;
has Bool    $.superscript                       is rw;
has Bool    $.subscript                         is rw;
has Bool    $.allupper                          is rw;
has Bool    $.alllower                          is rw;
has Bool    $.titlecase                         is rw;
has Bool    $.titlecaselowercase                is rw;
has Int     $.spacebefore                       is rw           = 0;
has Int     $.spaceafter                        is rw           = 0;
has Str     $.ANSI-spacebefore-pad                              = '';
has Str     $.ANSI-spaceafter-pad                               = '';
has Bool    $.bytes-unit-to-comma-round-bytes;
has Bool    $.bytes-unit-to-round-bytes;
has Bool    $.bytes-unit-to-comma-bytes;
has Bool    $.bytes-unit-to-bytes;
has Bool    $.bytes-to-bytes-unit;
has Bool    $.metric-unit-to-comma-round-number;
has Bool    $.metric-unit-to-round-number;
has Bool    $.metric-unit-to-comma-number;
has Bool    $.metric-unit-to-number;
has Bool    $.number-to-metric-unit;
has Bool    $.add-commas-to-digits;
has Bool    $.date-time;
has Bool    $.trim-input                                        = True;
has Mu:D    $.text                              is required;
has Mu      $.TEXT;
has Mu      $.ANSI;

submethod TWEAK {
    my $text        = $!text;
    $!text          = $text.trim if $!trim-input && $text ~~ Str;
    $!TEXT          = $!text;

    if $!date-time && my $dt = string-to-date-time($text) {
        $!TEXT      = $dt;
    }
    elsif $text ~~ / ^ (<[-+]>*) \s* (\d+) $ / {
        if $0.Str {
            $text   = $1.Str;
            $text   = $0.Str ~ $1.Str if $0.Str eq '-';
            $!TEXT  = $text;
        }
        if $!superscript {
            $!TEXT  = integer-to-superscript(+$text);
        }
        elsif $!subscript {
            $!TEXT  = integer-to-subscript(+$text);
        }
        elsif $!add-commas-to-digits {
            $!TEXT  = add-commas-to-digits($text.Int);
        }
        elsif $!number-to-metric-unit {
            $!TEXT  = number-to-metric-unit($text.Int);
        }
        elsif $!bytes-to-bytes-unit {
            $!TEXT  = bytes-to-bytes-unit($text.Int);
        }
    }
    elsif $text ~~ / ^ (<[-+]>)* \s* (\d+ '.' \d+) $ / {
        if $0.Str {
            $text   = $1.Str;
            $text   = $0.Str ~ $1.Str if $0.Str eq '-';
            $!TEXT  = $text;
        }
        if $!add-commas-to-digits {
            $!TEXT  = add-commas-to-digits($text);
        }
        elsif $!number-to-metric-unit {
            $!TEXT  = number-to-metric-unit($text.Int);
        }
    }
    else {
        if $!allupper {
            $!TEXT      = $text.uc;
        }
        elsif $!alllower {
            $!TEXT      = $text.lc;
        }
        elsif $!titlecase {
            $!TEXT      = $text.tc;
        }
        elsif $!titlecaselowercase {
            $!TEXT      = $text.tclc;
        }
        if $!bytes-unit-to-comma-round-bytes {
            $!TEXT  = bytes-unit-to-bytes($text, :commas, :round);
        }
        elsif $!bytes-unit-to-comma-bytes {
            $!TEXT  = bytes-unit-to-bytes($text, :commas);
        }
        elsif $!bytes-unit-to-round-bytes {
            $!TEXT  = bytes-unit-to-bytes($text, :round);
        }
        elsif $!bytes-unit-to-bytes {
            $!TEXT  = bytes-unit-to-bytes($text);
        }
        elsif $!metric-unit-to-comma-round-number {
            $!TEXT  = number-metric-unit-to-number($text, :commas, :round);
        }
        elsif $!metric-unit-to-comma-number {
            $!TEXT  = number-metric-unit-to-number($text, :commas);
        }
        elsif $!metric-unit-to-round-number {
            $!TEXT  = number-metric-unit-to-number($text, :round);
        }
        elsif $!metric-unit-to-number {
            $!TEXT  = number-metric-unit-to-number($text);
        }
    }
    self.ANSI-fmt;
    self;
}

method ANSI-fmt (*%options) {
    my $foreground;
    $foreground         = $!foreground                  if $!foreground;
    $foreground         = %options<foreground>          if %options<foreground>:exists;
    $!foreground-rgb    = Color::Names.color-data(<CSS3>).&find-color($foreground,  :exact).values.first<rgb>   if $foreground;

    my $background;
    $background         = $!background                  if $!background;
    $background         = %options<background>          if %options<background>:exists;
    my $highlight       = $!highlight;
    $highlight          = %options<highlight>           if %options<highlight>:exists;
    unless $background {
        $background     = $highlight                    if $highlight;
    }
    $!background-rgb    = Color::Names.color-data(<CSS3>).&find-color($background,  :exact).values.first<rgb>   if $background && $background !~~ Positional;
    $!highlight-rgb     = Color::Names.color-data(<CSS3>).&find-color($highlight,   :exact).values.first<rgb>   if $highlight  && $highlight  !~~ Positional;

    my $bold            = $!bold;
    $bold               = %options<bold>                if %options<bold>:exists;
    my $faint           = $!faint;
    $faint              = %options<faint>               if %options<faint>:exists;
    my $italic          = $!italic;
    $italic             = %options<italic>              if %options<italic>:exists;
    my $underline       = $!underline;
    $underline          = %options<underline>           if %options<underline>:exists;
    my $blink           = $!blink;
    $blink              = %options<blink>               if %options<blink>:exists;
    my $reverse         = $!reverse;
    $reverse            = %options<reverse>             if %options<reverse>:exists;
    my $hide            = $!hide;
    $hide               = %options<hide>                if %options<hide>:exists;
    my $strikethrough   = $!strikethrough;
    $strikethrough      = %options<strikethrough>       if %options<strikethrough>:exists;
    my $doubleunderline = $!doubleunderline;
    $doubleunderline    = %options<doubleunderline>     if %options<doubleunderline>:exists;

    $!ANSI-spacebefore-pad  = ' ' x $!spacebefore       if $!spacebefore;
    my @pre-effects     = ();
    my @post-effects    = ();
    my @pre-colors      = ();
    my @post-colors     = ();
    $!ANSI-spaceafter-pad   = ' ' x $!spaceafter        if $!spaceafter;

    if $!foreground-rgb {
        @pre-colors.push("\o33[38;2;" ~ $!foreground-rgb[0] ~ ';' ~ $!foreground-rgb[1] ~ ';' ~ $!foreground-rgb[2] ~ 'm');
        @post-colors.push("\o33[39m");
    }
    if $!background-rgb {
        @pre-colors.push("\o33[48;2;" ~ $!background-rgb[0] ~ ';' ~ $!background-rgb[1] ~ ';' ~ $!background-rgb[2] ~ 'm');
        @post-colors.push("\o33[49m");
    }
    if $!highlight-rgb {
        $!ANSI-spacebefore-pad  = "\o33[48;2;"
                                ~ $!highlight-rgb[0] ~ ';'
                                ~ $!highlight-rgb[1] ~ ';'
                                ~ $!highlight-rgb[2]
                                ~ 'm'
                                ~ $!ANSI-spacebefore-pad
                                ~ "\o33[49m" if $!spacebefore;
        $!ANSI-spaceafter-pad   = "\o33[48;2;"
                                ~ $!highlight-rgb[0] ~ ';'
                                ~ $!highlight-rgb[1] ~ ';'
                                ~ $!highlight-rgb[2]
                                ~ 'm'
                                ~ $!ANSI-spaceafter-pad
                                ~ "\o33[49m" if $!spaceafter;
    }
    if $bold {
        @pre-effects.push("\o33[1m");
        @post-effects.push("\o33[22m");
    }
    if $faint {
        @pre-effects.push("\o33[2m");
        @post-effects.push("\o33[22m");
    }
    if $italic {
        @pre-effects.push("\o33[3m");
        @post-effects.push("\o33[23m");
    }
    if $underline {
        @pre-effects.push("\o33[4m");
        @post-effects.push("\o33[24m");
    }
    if $blink {
        @pre-effects.push("\o33[5m");
        @post-effects.push("\o33[25m");
    }
    if $reverse {
        @pre-effects.push("\o33[7m");
        @post-effects.push("\o33[27m");
    }
    if $hide {
        @pre-effects.push("\o33[8m");
        @post-effects.push("\o33[28m");
    }
    if $strikethrough {
        @pre-effects.push("\o33[9m");
        @post-effects.push("\o33[29m");
    }
    if $doubleunderline {
        @pre-effects.push("\o33[21m");
        @post-effects.push("\o33[24m");
    }
    $!ANSI  = sprintf "%s%s%s%s%s", @pre-effects.join, @pre-colors.join, $!TEXT, @post-colors.join, @post-effects.join;
    return $!ANSI;
}

method TEXT-padded {
    return $!TEXT unless any($!spacebefore.so, $!spaceafter.so);
    return sprintf "%s%s%s", ' ' x $!spacebefore, $!TEXT, ' ' x $!spaceafter;
}

method ANSI-padded {
    return $!ANSI unless any($!spacebefore.so, $!spaceafter.so);
    return $!ANSI-spacebefore-pad ~ $!ANSI ~ $!ANSI-spaceafter-pad;
}

=finish
