unit class Our::Grid::To::GUI:api<1>:auth<Mark Devine (mark@markdevine.com)>;

use Our::Grid::Cell;

has $.body      is required;

use Our::Grid::Cell;
use GTK::Simple;
use GTK::Simple::App;
use GTK::Simple::Frame;
use GTK::Simple::TextView;
use GTK::Simple::VBox;

method GUI {
    my GTK::Simple::App $gui;
    $gui                       .= new(title => $!body.title, :720width, :600height);

    my $grid                    = GTK::Simple::Grid.new;
    loop (my $col = 0; $col < $!body.headings.elems; $col++) {
        my $VBox                = GTK::Simple::VBox.new;
        my $heading             = GTK::Simple::MarkUpLabel.new(text => '<span foreground="black" underline="single" weight="bold" size="large">' ~ $!body.headings[$col].TEXT ~ '</span>');
        $grid.attach:           [$col, 0, 1, 1] => $heading;
        for $!body.meta<sort-order>.list -> $row {
            my $body            = ' ';
            $body               = $!body.cells[$row][$col].TEXT when $!body.cells[$row][$col] ~~ Our::Grid::Cell:D;
            my $obj             = GTK::Simple::TextView.new;
            $obj.text           = $body;
            $obj.editable       = False;
            given $!body.cells[$row][$col].justification {
                when 'left'     { $obj.alignment = LEFT;    }
                when 'center'   { $obj.alignment = CENTER;  }
                when 'right'    { $obj.alignment = RIGHT;   }
                default         { $obj.alignment = FILL;    }
            }
            $obj.monospace      = True;
            $VBox.set-content:  $obj;
        }
        $VBox.border-width      = 20;
        $grid.attach:           [$col, 1, 1, 1] => $VBox;
    }
    $grid.baseline-row:         $!body.meta<sort-order>.elems;
    my $scrolled-grid           = GTK::Simple::ScrolledWindow.new;
    $scrolled-grid.set-content($grid);
#   my $exit-b                  = GTK::Simple::ToggleButton.new(label=>'Exit');
#   $exit-b.toggled.tap(-> $b { $gui.exit } );
#   my $VBox                    = GTK::Simple::VBox.new;
#   $VBox.set-content:          $scrolled-grid;
#   $VBox.set-content:          $exit-b;
    $gui.border-width           = 20;
#   $gui.set-content($VBox);
    $gui.set-content($scrolled-grid);
    $gui.run;
}

=finish
