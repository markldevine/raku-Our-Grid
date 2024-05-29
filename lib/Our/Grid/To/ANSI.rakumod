unit class Our::Grid::To::ANSI:api<1>:auth<Mark Devine (mark@markdevine.com)>;

use Color::Names:api<2>;
use Our::Grid::Cell;
use Our::Utilities;

use Data::Dump::Tree;

has $.body      is required;
has $.term-size is required;

my $white-rgb = Color::Names.color-data(<CSS3>).&find-color('white', :exact).values.first<rgb>;
my $background-set = "\o33[48;2;" ~ $white-rgb.list.join(';') ~ 'm';
my $background-unset = "\o33[49m";
my $black-rgb = Color::Names.color-data(<CSS3>).&find-color('black', :exact).values.first<rgb>;
my $foreground-set = "\o33[38;2;" ~ $black-rgb.list.join(';') ~ 'm';
my $foreground-unset = "\o33[39m";

method !ANSI-print-headings (Int:D :$col-width-total, Int:D :$margin, Str :$group?) {
    if $group {
        put ' ' x $margin
            ~ %box-char<side> ~ ' '
            ~ "\o33[1m\o33[3m"
#           ~ $foreground-set
#           ~ $background-set
            ~ $group
#           ~ $background-unset
#           ~ $foreground-unset
            ~ "\o33[22m\o33[23m"
            ~ ' ' x ($col-width-total - $group.chars - 1)
            ~ %box-char<side>;
        print ' ' x $margin ~ %box-char<side-row-left-sep>;
        loop (my $i = 0; $i < ($!body.meta<col-width>.elems - 1); $i++) {
            next if $i == $!body.group-by-column;
            print %box-char<horizontal> x ($!body.meta<col-width>[$i] + 2) ~ %box-char<down-and-horizontal>;
        }
        put %box-char<horizontal> x ($!body.meta<col-width>[*-1] + 2) ~ %box-char<side-row-right-sep>;
    }
    if $!body.headings.elems {
        print ' ' x $margin ~ %box-char<side>;
        loop (my $col = 0; $col < $!body.headings.elems; $col++) {
            next if $col == $!body.group-by-column;
            print ' ' ~ $!body.headings[$col].ANSI-fmt(:width($!body.meta<col-width>[$col]), :bold, :reverse($!body.meta<reverse-highlight>), :highlight<white>, :foreground<black>).ANSI-padded;
            print ' ' ~ %box-char<side>;
        }
        print "\n";
    }
}

method ANSI-print {
    return unless $*IN.t;
    my $col-width-total = 0;
    for $!body.meta<col-width>.list -> $colw {
        $col-width-total += $colw;
    }
    $col-width-total   += ($!body.meta<col-width>.elems * 3) - 1;
    $col-width-total -= ($!body.meta<col-width>[$!body.group-by-column] + 3) if $!body.group-by-column >= 0;
    my $margin          = ($!term-size.cols - ($col-width-total + 2)) div 2;
    if self.body.title {
        my $left-pad    = ($col-width-total - self.body.title.chars) div 2;
        my $right-pad   = $col-width-total - self.body.title.chars - $left-pad;
        put ' ' x $margin ~ %box-char<top-left-corner> ~ %box-char<horizontal> x $col-width-total ~ %box-char<top-right-corner>;
        put ' ' x $margin
            ~ %box-char<side>
            ~ ' ' x $left-pad
            ~ "\o33[1m"
            ~ $foreground-set
            ~ $background-set
            ~ self.body.title
            ~ $background-unset
            ~ $foreground-unset
            ~ "\o33[22m"
            ~ ' ' x $right-pad
            ~ %box-char<side>;
        if $!body.group-by-column >= 0 {
            put ' ' x $margin ~ %box-char<side-row-left-sep> ~ %box-char<horizontal> x $col-width-total ~ %box-char<side-row-right-sep>;
        }
        else {
            print ' ' x $margin ~ %box-char<side-row-left-sep>;
            loop (my $i = 0; $i < ($!body.meta<col-width>.elems - 1); $i++) {
                print %box-char<horizontal> x ($!body.meta<col-width>[$i] + 2) ~ %box-char<down-and-horizontal>;
            }
            put %box-char<horizontal> x ($!body.meta<col-width>[*-1] + 2) ~ %box-char<side-row-right-sep>;
        }
    }
    self!ANSI-print-headings(:$col-width-total, :$margin)  unless $!body.group-by-column >= 0;
    my $current-group       = '';
    for $!body.meta<sort-order>.list -> $row {
        if $!body.group-by-column >= 0 {
            if $!body.cells[$row][$!body.group-by-column] ~~ Our::Grid::Cell:D {
                if $current-group ne $!body.cells[$row][$!body.group-by-column].TEXT {
                    my Bool $first;
                    $first  = True unless $current-group.chars;
                    $current-group = $!body.cells[$row][$!body.group-by-column].TEXT;
                    unless $first {
                        print ' ' x $margin ~ %box-char<side-row-left-sep>;
                        loop (my $i = 0; $i < ($!body.meta<col-width>.elems - 1); $i++) {
                            next if $i == $!body.group-by-column;
                            print %box-char<horizontal> x ($!body.meta<col-width>[$i] + 2) ~ %box-char<up-and-horizontal>;
                        }
                        put %box-char<horizontal> x ($!body.meta<col-width>[*-1] + 2) ~ %box-char<side-row-right-sep>;
                    }
                    self!ANSI-print-headings(:$col-width-total, :$margin, :group($current-group));
                }
            }
        }
        print ' ' x $margin;
        loop (my $col = 0; $col < $!body.cells[$row].elems; $col++) {
            next if $col == $!body.group-by-column;
            print %box-char<side> ~ ' ';
            given $!body.cells[$row][$col] {
                when Our::Grid::Cell:D  {
                    print $!body.cells[$row][$col].ANSI-fmt(:width($!body.meta<col-width>[$col])).ANSI-padded;
                }
                default                 {
                    print ' ' x $!body.meta<col-width>[$col];
                }
            }
            print ' ';
        }
        put %box-char<side>;
    }

    print ' ' x $margin ~ %box-char<bottom-left-corner>;
    loop (my $i = 0; $i < ($!body.meta<col-width>.elems - 1); $i++) {
        next if $i == $!body.group-by-column;
        print %box-char<horizontal> x ($!body.meta<col-width>[$i] + 2) ~ %box-char<up-and-horizontal>;
    }
    put %box-char<horizontal> x ($!body.meta<col-width>[*-1] + 2) ~ %box-char<bottom-right-corner>;
}

=finish
