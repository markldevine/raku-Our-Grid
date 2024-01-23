unit class Our::Grid::Cell:api<1>:auth<Mark Devine (mark@markdevine.com)>;

use Our::Grid::Cell::Fragment;
use Our::Utilities;

enum Justification is export ( 
    justify-left    => 1, 
    justify-center  => 2, 
    justify-right   => 3, 
);

has                 $.fragments;
has                 $.text;
has                 $.ANSI              is built(False);
has                 $.TEXT              is built(False);
has Justification   $.justification     is rw               = justify-left;
has uint            $.my-row            is rw               = 0;                # self-aware coordinates
has uint            $.my-col            is rw               = 0;                # self-aware coordinates
has uint            $.row               is rw               = 0;
has uint            $.col               is rw               = 0;
has uint            $.visibility        is rw               = 100;              # % of mandatory visibility upon display
has uint            $.width             is rw               = 0;
has uint            $!spacebefore                           = 0;
has uint            $!spaceafter                            = 0;
has                 %.options;

submethod BUILD(:$text,
                :$fragments,
                :$row,
                :$col,
                :$justification,
                :$width,
                *%options,
               ) {
    die "Must initialize with either ':text' or ':fragments'" unless $text || $fragments;
    $!text          = $text;
    $!row           = $row              with $row;
    $!col           = $col              with $col;
    $!width         = $width            with $width;
put $!width;
    $!justification = $justification    with $justification;
put $!justification;
    die "Must send both 'row' & 'col' together" if any($!row.so, $!col.so) && ! all($!row.so, $!col.so);
    %!options       = %options;
    $!fragments     = $fragments with $fragments;
    $!fragments[0]  = Our::Grid::Cell::Fragment.new(:$!text, |%options) unless $!fragments;
}

submethod TWEAK {
    self.TEXT-fmt();
    self.ANSI-fmt();
}

method !justify {
    my $text-chars      = $!TEXT.chars + $!fragments[0].spacebefore + $!fragments[*-1].spaceafter;
    die 'Unable to fit cell in ' ~ $!width ~ ' character wide cell!' if $!width < $text-chars;
    return              if $!width == $text-chars;
    if $!justification ~~ justify-left {
        $!fragments[*-1].cell-spaceafter = $!width - $text-chars;
    }
    elsif $!justification ~~ justify-center {
        $!fragments[0].cell-spacebefore = ($!width - $text-chars) div 2;
        $!fragments[*-1].cell-spaceafter = $!width - $text-chars - $!fragments[0].cell-spacebefore;
    }
    elsif $!justification ~~ justify-right {
        $!fragments[0].cell-spacebefore = $!width - $text-chars;
    }
}

method TEXT-fmt (*%options) {
    my %opts;
    %opts                   = %options if %options.elems;
    $!TEXT                  = Nil;
    for $!fragments.list -> $fragment {
        $!TEXT             ~= $fragment.TEXT-fmt(|%opts);
    }
    my $text-chars          = $!TEXT.chars + $!fragments[0].spacebefore + $!fragments[*-1].spaceafter;
    die 'Unable to fit cell in ' ~ $!width ~ ' character wide cell!' if $!width < $text-chars;
    return                  if $!width == $text-chars;
    if $!justification ~~ justify-left {
        $!fragments[*-1].cell-spaceafter = $!width - $text-chars;
    }
    elsif $!justification ~~ justify-center {
        $!fragments[0].cell-spacebefore = ($!width - $text-chars) div 2;
        $!fragments[*-1].cell-spaceafter = $!width - $text-chars - $!fragments[0].cell-spacebefore;
    }
    elsif $!justification ~~ justify-right {
        $!fragments[0].cell-spacebefore = $!width - $text-chars;
    }
}


method ANSI-fmt (*%options) {
    my %opts;
    %opts                   = %options if %options.elems;
    $!ANSI                  = Nil;
#%%%$!ANSI                  = sprintf("\o33[%d;%dH", $!row, $!col) if $!row || $!col;                   #%%% uncomment when implementing direct screen addressing
    for $!fragments.list -> $fragment {
        $!ANSI             ~= $fragment.ANSI-fmt(|%opts);
    }
}

=finish
