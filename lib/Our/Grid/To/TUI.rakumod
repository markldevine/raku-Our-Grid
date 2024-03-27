unit class Our::Grid::To::TUI:api<1>:auth<Mark Devine (mark@markdevine.com)>;

use Terminal::UI 'ui';
use Our::Grid::Cell;

has $.body      is required;
has $.term-size is required;

method TUI {
    my $erase-char          = qx/stty -a/;
    $erase-char            ~~ s/ ^ .+? \s 'erase' \s '=' \s (..) ';' .+ $ /$0/;
    ui.setup: heights => [ 1, 1, fr => 1, 1];
    my \Title               = ui.panes[0];
    my \Headings            = ui.panes[1];
    my \Body                = ui.panes[2];
    my \Footer              = ui.panes[3];
    Body.auto-scroll        = False;
#   Title
    Title.put: ' ' x ((($!term-size.cols - $!body.title.chars) div 2) - 1) ~ $!body.title;
#   Margin
    my $col-width-total     = 0;
    for $!body.meta<col-width>.list -> $colw {
        $col-width-total   += $colw;
    }
    $col-width-total       += ($!body.meta<col-width>.elems * 2) - 2;
    my $margin              = (($!term-size.cols - $col-width-total) div 2) - 1;
#   Headings
    if $!body.headings.elems {
        my $headings        = ' ' x ($margin - 1);
        loop (my $col = 0; $col < $!body.headings.elems; $col++) {
            $headings          ~= ' ';
            $headings          ~= $!body.headings[$col].TEXT-padded(:width($!body.meta<col-width>[$col]));
            $headings          ~= ' ' unless $col == ($!body.headings.elems - 1);
        }
        Headings.put: $headings;
    }
#   Body
    my $body-record;
    for $!body.meta<sort-order>.list -> $row {
        $body-record = ' ' x $margin;
        loop (my $col = 0; $col < $!body.cells[$row].elems; $col++) {
            $body-record ~= ' ' unless $col == 0;
            given $!body.cells[$row][$col] {
                when Our::Grid::Cell:D  {
                    my $record      = $!body.cells[$row][$col].ANSI-fmt(:width($!body.meta<col-width>[$col])).ANSI-padded;
                    $record         = $record.trim-trailing if $col == ($!body.cells[$row].elems - 1);
                    $body-record   ~= $record;
                }
                default                 {
                    $body-record   ~= ' ' x $!body.meta<col-width>[$col] unless $col == ($!body.cells[$row].elems - 1);
                }
            }
            $body-record ~= ' ' unless $col == ($!body.cells[$row].elems - 1);
        }
        Body.put: $body-record;
    }
    Footer.put: " Press 'q' to quit";
    ui.focus(pane => 2);
    ui.interact;
    ui.shutdown;
    qqx/stty erase $erase-char/;
}

=finish
