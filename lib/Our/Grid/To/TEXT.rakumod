unit class Our::Grid::To::TEXT:api<1>:auth<Mark Devine (mark@markdevine.com)>;

use Our::Grid::Cell;

has $.body  is required;

method !TEXT-print-headings {
    loop (my $col = 0; $col < $!body.headings.elems; $col++) {
        next if $col == $!body.group-by-column;
        print ' ' ~ $!body.headings[$col].TEXT-padded(:width($!body.meta<col-width>[$col]));
        print ' ' unless $col == ($!body.headings.elems - 1);
    }
    print "\n"  if $!body.headings.elems;
    loop ($col = 0; $col < $!body.headings.elems; $col++) {
        next if $col == $!body.group-by-column;
        print ' ' ~ '-' x $!body.meta<col-width>[$col];
        print ' ' unless $col == ($!body.headings.elems - 1);
    }
    print "\n"  if $!body.headings.elems;
}

method TEXT-print {
#   return False unless self!grid-check;
    my Bool $print-headings = True;
    my $current-group       = '';
    for $!body.meta<sort-order>.list -> $row {
        if $!body.group-by-column >= 0 {
            if $!body.cells[$row][$!body.group-by-column] ~~ Our::Grid::Cell:D {
                if $current-group ne $!body.cells[$row][$!body.group-by-column].TEXT {
                    $current-group = $!body.cells[$row][$!body.group-by-column].TEXT;
                    put "\n" ~ '[>>> ' ~ $!body.cells[$row][$!body.group-by-column].TEXT ~ ' <<<]';
                    self!TEXT-print-headings;
                }
            }
        }
        elsif $print-headings {
            self!TEXT-print-headings;
            $print-headings = False;
        }
        loop (my $col = 0; $col < $!body.cells[$row].elems; $col++) {
            next if $col == $!body.group-by-column;
            print ' ';
            given $!body.cells[$row][$col] {
                when Our::Grid::Cell:D  { print $!body.cells[$row][$col].TEXT-padded(:width($!body.meta<col-width>[$col]));  }
                default                 { print ' ' x $!body.meta<col-width>[$col];                                    }
            }
            print ' ' unless $col == ($!body.cells[$row].elems - 1);
        }
        print " \n";
    }
}

=finish
