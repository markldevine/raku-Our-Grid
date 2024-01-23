unit class Our::Grid::Cell::Fragment:api<1>:auth<Mark Devine (mark@markdevine.com)>;

use Our::Utilities;

has ANSI-Colors $.foreground                    is rw;
has ANSI-Colors $.background                    is rw;
has Bool        $.bold                          is rw;
has Bool        $.faint                         is rw;
has Bool        $.italic                        is rw;
has Bool        $.underline                     is rw;
has Bool        $.blink                         is rw;
has Bool        $.reverse                       is rw;
has Bool        $.hide                          is rw;
has Bool        $.strikethrough                 is rw;
has Bool        $.doubleunderline               is rw;
has Bool        $.superscript                   is rw;
has Bool        $.subscript                     is rw;
has Bool        $.allupper                      is rw;
has Bool        $.alllower                      is rw;
has Bool        $.titlecase                     is rw;
has Bool        $.titlecaselowercase            is rw;
has Int         $.spacebefore                   is rw           = 0;
has Int         $.spaceafter                    is rw           = 0;
has Bool        $.bytes-unit-to-comma-bytes                     = False;
has Bool        $.bytes-unit-to-bytes                           = False;
has Bool        $.bytes-to-bytes-unit                           = False;
has Bool        $.metric-unit-to-comma-number                   = False;
has Bool        $.metric-unit-to-number                         = False;
has Bool        $.number-to-metric-unit                         = False;
has Bool        $.add-commas-to-digits                          = False;
has Bool        $.date-time;
has Mu:D        $.text                          is required;
has Mu          $.TEXT;

submethod TWEAK {

#put '$!date-time                    = <' ~ $!date-time                      ~ '>'   if $!date-time;
#put '$!add-commas-to-digits         = <' ~ $!add-commas-to-digits           ~ '>'   if $!add-commas-to-digits;

#put '$!bytes-to-bytes-unit          = <' ~ $!bytes-to-bytes-unit            ~ '>'   if $!bytes-to-bytes-unit;
#put '$!bytes-unit-to-bytes          = <' ~ $!bytes-unit-to-bytes            ~ '>'   if $!bytes-unit-to-bytes;
#put '$!bytes-unit-to-comma-bytes    = <' ~ $!bytes-unit-to-comma-bytes      ~ '>'   if $!bytes-unit-to-comma-bytes;

#put '$!number-to-metric-unit        = <' ~ $!number-to-metric-unit          ~ '>'   if $!number-to-metric-unit;
#put '$!metric-unit-to-number        = <' ~ $!metric-unit-to-number          ~ '>'   if $!metric-unit-to-number;
#put '$!metric-unit-to-comma-number  = <' ~ $!metric-unit-to-comma-number    ~ '>'   if $!metric-unit-to-comma-number;

    my $text        = $!text.trim;
    $!TEXT          = $text;

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
        if $!bytes-unit-to-comma-bytes {
            $!TEXT  = bytes-unit-to-bytes($text, :commas);
        }
        elsif $!bytes-unit-to-bytes {
            $!TEXT  = bytes-unit-to-bytes($text);
        }
        elsif $!metric-unit-to-comma-number {
            $!TEXT  = number-metric-unit-to-number($text, :commas);
        }
        elsif $!metric-unit-to-number {
            $!TEXT  = number-metric-unit-to-number($text);
        }
    }
}

method TEXT-fmt (*%options) {
    my $spacebefore-pad = '';
    my $spacebefore     = $!spacebefore;
    $spacebefore        = %options<spacebefore>         with %options<spacebefore>;
    $spacebefore-pad    = ' ' x $spacebefore;

    my $spaceafter-pad  = '';
    my $spaceafter      = $!spaceafter;
    $spaceafter         = %options<spaceafter>          with %options<spaceafter>;
    $spaceafter-pad     = ' ' x $spaceafter;

    return sprintf("%s%s%s", $spacebefore-pad, $!TEXT, $spaceafter-pad);
}

method ANSI-fmt (*%options) {

    my $spacebefore-pad = '';
    my $spacebefore     = $!spacebefore;
    $spacebefore        = %options<spacebefore>         with %options<spacebefore>;
    $spacebefore-pad    = ' ' x $spacebefore;

    my $spaceafter-pad  = '';
    my $spaceafter      = $!spaceafter;
    $spaceafter         = %options<spaceafter>          with %options<spaceafter>;
    $spaceafter-pad     = ' ' x $spaceafter;

    my $foreground;
    $foreground         = $!foreground.value            if $!foreground;
    $foreground         = %options<foreground>.value    if %options<foreground>:exists;
    my $background;
    $background         = $!background.value            if $!background;
    $background         = %options<background>.value    if %options<background>:exists;

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

    my @pre-effects     = ();
    my @post-effects    = ();
    my @pre-colors      = ();
    my @post-colors     = ();

    if $foreground {
        @pre-colors.push("\o33[38;5;" ~ $foreground ~ 'm');
        @post-colors.push("\o33[39m");
    }
    if $background {
        @pre-colors.push("\o33[48;5;" ~ $background ~ 'm');
        @post-colors.push("\o33[49m");
        $spacebefore-pad = "\o33[48;5;" ~ $background ~ 'm' ~ $spacebefore-pad ~ "\o33[49m" if $spacebefore;
        $spaceafter-pad  = "\o33[48;5;" ~ $background ~ 'm' ~ $spaceafter-pad  ~ "\o33[49m" if $spaceafter;
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
    return sprintf("%s%s%s%s%s%s%s",
        $spacebefore-pad,
        @pre-effects.join,
        @pre-colors.join,
        $!TEXT,
        @post-colors.join,
        @post-effects.join,
        $spaceafter-pad,
    );
}

=finish
