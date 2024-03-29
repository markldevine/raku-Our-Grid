Our::Grid
=========
Load a grid, then output it in convenient ways.

In the "royal Our::" namespace, as I want to hack on this 
as alpha for a while.

SYNOPSIS
========

~~~raku
#!/usr/bin/env raku

use Our::Grid;

my Our::Grid $grid .= new;

#  PID TTY          TIME CMD
# 8654 pts/2    00:00:00 bash
# 8751 pts/2    00:00:00 ps

my grammar PS-grammar {
    token TOP       { <data> || <heading> }
    token heading   {
                        ^ \s*
                        $<h0>=[\w+] \s+ 
                        $<h1>=[\w+] \s+
                        $<h2>=[\w+] \s+
                        $<h3>=[\w+]
                        $
                    }
    token data      {
                        ^ \s*
                        $<d0>=[\d+] \s+
                        $<d1>=[.+?] \s+
                        $<d2>=[\d\d':'\d\d':'\d\d] \s+
                        $<d3>=[.+?] \s*
                        $
                    }
}

my class PS-actions {
    method heading ($/) {
        $grid.add-heading:  $/<h0>.Str;
        $grid.add-heading:  $/<h1>.Str;
        $grid.add-heading:  $/<h2>.Str;
        $grid.add-heading:  $/<h3>.Str;
    }
    method data ($/) {
        $grid.add-cell:     $/<d0>.Str, :superscript;
        $grid.add-cell:     $/<d1>.Str, :foreground<yellow>, :background<green>, :italic, :faint;
        $grid.add-cell:     $/<d2>.Str, :foreground<brown>;
        my $proc-name       = $/<d3>.Str;
        if $proc-name eq 'raku' {
            $grid.add-cell: $proc-name, :bold, :blink;
        }
        else {
            $grid.add-cell: $proc-name;
        }
        $grid.current-row++;
    }
}

for qx|/usr/bin/ps -e|.lines -> $ps {
    PS-grammar.parse($ps, :actions(PS-actions.new)) or warn;
}

sub MAIN (
    Bool    :$csv,  #= dump CSV to STDOUT
    Bool    :$gui,  #= Graphical User Interface
    Bool    :$html, #= dump HTML to STDOUT
    Bool    :$json, #= dump JSON to STDOUT
    Bool    :$text, #= TEXT print
    Bool    :$tui,  #= Terminal User Interface
    Bool    :$xml,  #= dump XML to STDOUT
) {
    $grid.sort-by-columns(:sort-columns([2,0]), :descending);
    when    $csv    { $grid.csv-print   }
    when    $gui    { $grid.GUI         }
    when    $html   { $grid.html-print  }
    when    $json   { $grid.json-print  }
    when    $text   { $grid.TEXT-print  }
    when    $tui    { $grid.TUI         }
    when    $xml    { $grid.xml-print   }
    default         { $grid.ANSI-print  }
}
~~~

NOTES
=====
All functionality works on xterm terminals (TERM=xterm | TERM=xterm-256color), but the ANSI escapes
(notably 'blink') are hit or miss on other TERM types.

AUTHOR
======
Mark Devine <mark@markdevine.com>
