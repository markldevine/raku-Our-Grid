unit class Our::Phrase:api<1>:auth<Mark Devine (mark@markdevine.com)>;

use Our::Utilities;

enum ANSI-Colors is export (
    black               => 16,
    blue                => 21,
    cyan                => 51,
    green               => 46,
    magenta             => 201,
    orange              => 202,
    red                 => 196,
    white               => 231,
    yellow              => 226,
);

enum ANSI-Effects is export (
    bold                => 1,
    faint               => 2,
    italic              => 3,
    underline           => 4,
    blink               => 5,
    reverse             => 7,
    hide                => 8,
    strikethrough       => 9,
    doubleunderline     => 21,
    superscript         => 73,
    subscript           => 74,
);

has ANSI-Colors $.foreground;                           # \o33[38;5;<n>m    TEXT    \o33[39m
has ANSI-Colors $.background;                           # \o33[48;5;<n>m    TEXT    \o33[49m
has Bool        $.bold;                                 # \o33[1m           TEXT    \o33[22m
has Bool        $.faint;                                # \o33[2m           TEXT    \o33[22m
has Bool        $.italic;                               # \o33[3m           TEXT    \o33[23m
has Bool        $.underline;                            # \o33[4m           TEXT    \o33[24m
has Bool        $.blink;                                # \o33[5m           TEXT    \o33[25m
has Bool        $.reverse;                              # \o33[7m           TEXT    \o33[27m
has Bool        $.hide;                                 # \o33[8m           TEXT    \o33[28m
has Bool        $.strikethrough;                        # \o33[9m           TEXT    \o33[29m
has Bool        $.doubleunderline;                      # \o33[21m          TEXT    \o33[24m
has Bool        $.superscript;
has Bool        $.subscript;
has Bool        $.allupper;
has Bool        $.alllower;
has Bool        $.titlecase;
has Bool        $.titlecaselowercase;
has Int         $.spacebefore           = 0;
has Int         $.spaceafter            = 0;
has Int         $.tabbefore             = 0;
has Int         $.tabafter              = 0;
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
