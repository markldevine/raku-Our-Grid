unit class Our::Grid::Cell::Fragment:api<1>:auth<Mark Devine (mark@markdevine.com)>;

use Our::Utilities;

has ANSI-Colors $.foreground            is rw;
has ANSI-Colors $.background            is rw;
has Bool        $.bold                  is rw;
has Bool        $.faint                 is rw;
has Bool        $.italic                is rw;
has Bool        $.underline             is rw;
has Bool        $.blink                 is rw;
has Bool        $.reverse               is rw;
has Bool        $.hide                  is rw;
has Bool        $.strikethrough         is rw;
has Bool        $.doubleunderline       is rw;
has Bool        $.superscript           is rw;
has Bool        $.subscript             is rw;
has Bool        $.allupper              is rw;
has Bool        $.alllower              is rw;
has Bool        $.titlecase             is rw;
has Bool        $.titlecaselowercase    is rw;
has Int         $.spacebefore           is rw   = 0;
has Int         $.spaceafter            is rw   = 0;
has Int         $.tabbefore             is rw   = 0;
has Int         $.tabafter              is rw   = 0;
has Str:D       $.text                  is required;
has Str         $.TEXT;

submethod TWEAK {
    $!TEXT          = $!text;
    if $!text ~~ / ^ \d+ $ / {
        if $!superscript {
            $!TEXT  = integer-to-superscript(+$!text);
        }
        elsif $!subscript {
            $!TEXT  = integer-to-subscript(+$!text);
        }
    }
    if $!allupper {
        $!TEXT      = $!text.uc;
    }
    elsif $!alllower {
        $!TEXT      = $!text.lc;
    }
    elsif $!titlecase {
        $!TEXT      = $!text.tc;
    }
    elsif $!titlecaselowercase {
        $!TEXT      = $!text.tclc;
    }
}

method ANSI-fmt {
    my @pre-effects     = ();
    my @post-effects    = ();
    my @pre-colors      = ();
    my @post-colors     = ();
    if $!foreground {
        @pre-colors.push("\o33[38;5;" ~ $!foreground.value ~ 'm');
        @post-colors.push("\o33[39m");
    }
    if $!background {
        @pre-colors.push("\o33[48;5;" ~ $!background.value ~ 'm');
        @post-colors.push("\o33[49m");
    }
    if $!bold {
        @pre-effects.push("\o33[1m");
        @post-effects.push("\o33[22m");
    }
    if $!faint {
        @pre-effects.push("\o33[2m");
        @post-effects.push("\o33[22m");
    }
    if $!italic {
        @pre-effects.push("\o33[3m");
        @post-effects.push("\o33[23m");
    }
    if $!underline {
        @pre-effects.push("\o33[4m");
        @post-effects.push("\o33[24m");
    }
    if $!blink {
        @pre-effects.push("\o33[5m");
        @post-effects.push("\o33[25m");
    }
    if $!reverse {
        @pre-effects.push("\o33[7m");
        @post-effects.push("\o33[27m");
    }
    if $!hide {
        @pre-effects.push("\o33[8m");
        @post-effects.push("\o33[28m");
    }
    if $!strikethrough {
        @pre-effects.push("\o33[9m");
        @post-effects.push("\o33[29m");
    }
    if $!doubleunderline {
        @pre-effects.push("\o33[21m");
        @post-effects.push("\o33[24m");
    }
    return sprintf("%s%s%s%s%s%s%s%s%s",
        $!spacebefore > 0   ?? ' '  xx $!spacebefore    !! '',
        $!tabbefore   > 0   ?? "\t" xx $!tabbefore      !! '',
        @pre-effects.join,
        @pre-colors.join,
        $!TEXT,
        @post-colors.join,
        @post-effects.join,
        $!spaceafter  > 0   ?? ' '  xx $!spaceafter     !! '',
        $!tabafter    > 0   ?? "\t" xx $!tabafter       !! '',
    );
}

method TEXT-fmt {
    return sprintf("%s%s%s%s%s",
        $!spacebefore > 0   ?? ' '  xx $!spacebefore    !! '',
        $!tabbefore   > 0   ?? "\t" xx $!tabbefore      !! '',
        $!TEXT,
        $!spaceafter  > 0   ?? ' '  xx $!spaceafter     !! '',
        $!tabafter    > 0   ?? "\t" xx $!tabafter       !! '',
    );
}

=finish
