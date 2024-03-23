unit class Our::Grid::To::HTML:api<1>:auth<Mark Devine (mark@markdevine.com)>;

use Data::Dump::Tree;
use Base64::Native;
use Color::Names:api<2>;
use Our::Cache;
use Our::Grid::Cell;
use Our::Grid::Cell::Fragment;
use Our::Redis;
use Our::Utilities;

role Table-Properties {
background-color
border
border-collapse
border-spacing
caption-side
color
empty-cells
font-family
font-size
font-style
font-variant
font-weight
letter-spacing
line-height
list-style
list-style-image
list-style-position
list-style-type
padding
text-align
text-decoration
text-indent
text-shadow
text-transform
vertical-align
white-space
word-spacing
}

role Table-Row-Properties {
background-color
border
color
font-family
font-size
font-style
font-variant
font-weight
height
line-height
list-style
list-style-image
list-style-position
list-style-type
padding
text-align
text-decoration
text-indent
text-shadow
text-transform
vertical-align
white-space
width
word-spacing
}

role Table-TD-Properties {
align
background-color
background-image
background-position
background-repeat
border
border-collapse
border-spacing
bottom
box-shadow
caption-side
clear
color
content
cursor
display
empty-cells
filter
float
font-family
font-size
font-style
font-variant
font-weight
height
left
letter-spacing
line-height
list-style
list-style-image
list-style-position
list-style-type
margin
max-height
max-width
min-height
min-width
opacity
outline
overflow
padding
position
right
text-align
text-decoration
text-indent
text-shadow
text-transform
top
vertical-align
visibility
white-space
width
word-spacing
z-index
}

#   redis the organization's color scheme...

my $indentation-level                   = 12;

my class Paragraph-Heading-Style {
    has $.background-color  = '#009cde';                    # Metro blue
    has $.border            = '1px solid #9fabbb';          # grayish blue
    has $.font-family       = 'arial, verdana, sans-serif';
    has $.font-size         = 12;                           # points
    has $.font-weight       = 700;                          # bold (700/1000)
    has $.margin-bottom     = 5;                            # pixels
    has $.padding-bottom    = 1;                            # pixels
    has $.padding-left      = 9;                            # pixels
    has $.padding-right     = 10;                           # pixels
    has $.padding-top       = 1;                            # pixels

    method generate () {
        my $style           = ' ' x $indentation-level;
        $style             ~= '<style>.paragraph-heading {';
        $style             ~= ' background-color: ' ~ self.background-color ~ ';';
        $style             ~= ' border: '           ~ self.border           ~ ';';
        $style             ~= ' font-family: '      ~ self.font-family      ~ ';';
        $style             ~= ' font-size: '        ~ self.font-size        ~ 'pt;';
        $style             ~= ' font-weight: '      ~ self.font-weight      ~ ';';
        $style             ~= ' margin-bottom: '    ~ self.margin-bottom    ~ 'px;';
        $style             ~= ' padding-left: '     ~ self.padding-left     ~ 'px;';
        $style             ~= ' padding-right: '    ~ self.padding-right    ~ 'px;';
        $style             ~= ' padding-top: '      ~ self.padding-top      ~ 'px;';
        $style             ~= ' padding-bottom: '   ~ self.padding-bottom   ~ 'px;';
        $style             ~= ' }</style>';
        return $style;
    }
}

my class Table-Heading-Style {
    has $.background-color  = '#d0d0d0';                    # light gray
    has $.border-bottom     = '1px solid #cccccc';          # light gray
    has $.border-left       = '0px solid #cccccc';          # light gray
    has $.border-right      = '1px solid #cccccc';          # light gray
    has $.border-top        = '0px solid #cccccc';          # light gray
    has $.color             = '#000000';                    # black
    has $.font-family       = 'arial, verdana, sans-serif';
    has $.font-size         = 11;
    has $.font-weight       = 700;                          # bold (700/1000)
    has $.margin            = 0;                            # pixels
    has $.padding-bottom    = 1;                            # pixels
    has $.padding-left      = 5;                            # pixels
    has $.padding-right     = 5;                            # pixels
    has $.padding-top       = 0;                            # pixels

    method generate () {
        my $style           = ' ' x $indentation-level;
        $style             ~= '<style>.table-heading {';
        $style             ~= ' background-color: ' ~ self.background-color ~ ';';
        $style             ~= ' border-left: '      ~ self.border-left      ~ ';';
        $style             ~= ' border-right: '     ~ self.border-right     ~ ';';
        $style             ~= ' border-top: '       ~ self.border-top       ~ ';';
        $style             ~= ' border-bottom: '    ~ self.border-bottom    ~ ';';
        $style             ~= ' color: '            ~ self.color            ~ ';';
        $style             ~= ' font-family: '      ~ self.font-family      ~ ';';
        $style             ~= ' font-size: '        ~ self.font-size        ~ 'pt;';
        $style             ~= ' font-weight: '      ~ self.font-weight      ~ ';';
        $style             ~= ' margin: '           ~ self.margin           ~ 'px;';
        $style             ~= ' padding-bottom: '   ~ self.padding-bottom   ~ 'px;';
        $style             ~= ' padding-left: '     ~ self.padding-left     ~ 'px;';
        $style             ~= ' padding-right: '    ~ self.padding-right    ~ 'px;';
        $style             ~= ' padding-top: '      ~ self.padding-top      ~ 'px;';
        $style             ~= ' }</style>';
        return $style;
    }
}

my class Table-Row-Even-Style {
    has $.background-color  = '#f0f0f0';                    # very light gray
    has $.border-bottom     = '1px solid #cccccc';          # light gray
    has $.border-left       = '0px solid #cccccc';          # light gray
    has $.border-right      = '1px solid #cccccc';          # light gray
    has $.border-top        = '0px solid #cccccc';          # light gray
    has $.color             = '#000000';                    # black
    has $.font-family       = 'arial, verdana, sans-serif';
    has $.font-size         = 9;                            # points
    has $.font-weight       = 400;                          # normal (400/1000)
    has $.margin            = 0;                            # pixels
    has $.padding-bottom    = 1;                            # pixels
    has $.padding-left      = 5;                            # pixels
    has $.padding-right     = 5;                            # pixels
    has $.padding-top       = 0;                            # pixels

    method generate () {
        my $style           = ' ' x $indentation-level;
        $style             ~= '<style>.table-row {';
        $style             ~= ' background-color: ' ~ self.even-background-color            ~ ';';
        $style             ~= ' border-bottom: '    ~ self.border-bottom                    ~ ';';
        $style             ~= ' border-left: '      ~ self.border-left                      ~ ';';
        $style             ~= ' border-right: '     ~ self.border-right                     ~ ';';
        $style             ~= ' border-top: '       ~ self.border-top                       ~ ';';
        $style             ~= ' color: '            ~ self.color                            ~ ';';
        $style             ~= ' font-family: '      ~ self.font-family                      ~ ';';
        $style             ~= ' font-size: '        ~ self.font-size                        ~ 'pt;';
        $style             ~= ' font-weight: '      ~ self.font-weight                      ~ ';';
        $style             ~= ' margin: '           ~ self.margin                           ~ 'px;';
        $style             ~= ' padding-bottom: '   ~ self.padding-bottom                   ~ 'px;';
        $style             ~= ' padding-left: '     ~ self.padding-left                     ~ 'px;';
        $style             ~= ' padding-right: '    ~ self.padding-right                    ~ 'px;';
        $style             ~= ' padding-top: '      ~ self.padding-top                      ~ 'px;';
        $style             ~= ' }</style>';
        return $style;
    }
}

my class Table-Row-Odd-Style {
    has $.background-color  = '#ffffff';                    # white
    has $.border-bottom     = '1px solid #cccccc';          # light gray
    has $.border-left       = '0px solid #cccccc';          # light gray
    has $.border-right      = '1px solid #cccccc';          # light gray
    has $.border-top        = '0px solid #cccccc';          # light gray
    has $.color             = '#000000';                    # black
    has $.font-family       = 'arial, verdana, sans-serif';
    has $.font-size         = 9;                            # points
    has $.font-weight       = 400;                          # normal (400/1000)
    has $.margin            = 0;                            # pixels
    has $.padding-bottom    = 1;                            # pixels
    has $.padding-left      = 5;                            # pixels
    has $.padding-right     = 5;                            # pixels
    has $.padding-top       = 0;                            # pixels

    method generate () {
        my $style           = ' ' x $indentation-level;
        $style             ~= '<style>.table-row {';
        $style             ~= ' background-color: ' ~ self.even-background-color            ~ ';';
        $style             ~= ' border-bottom: '    ~ self.border-bottom                    ~ ';';
        $style             ~= ' border-left: '      ~ self.border-left                      ~ ';';
        $style             ~= ' border-right: '     ~ self.border-right                     ~ ';';
        $style             ~= ' border-top: '       ~ self.border-top                       ~ ';';
        $style             ~= ' color: '            ~ self.color                            ~ ';';
        $style             ~= ' font-family: '      ~ self.font-family                      ~ ';';
        $style             ~= ' font-size: '        ~ self.font-size                        ~ 'pt;';
        $style             ~= ' font-weight: '      ~ self.font-weight                      ~ ';';
        $style             ~= ' margin: '           ~ self.margin                           ~ 'px;';
        $style             ~= ' padding-bottom: '   ~ self.padding-bottom                   ~ 'px;';
        $style             ~= ' padding-left: '     ~ self.padding-left                     ~ 'px;';
        $style             ~= ' padding-right: '    ~ self.padding-right                    ~ 'px;';
        $style             ~= ' padding-top: '      ~ self.padding-top                      ~ 'px;';
        $style             ~= ' }</style>';
        return $style;
    }
}

my class Button-Style {
    has $.background-color  = '#009cde';                    # white
    has $.border-bottom     = '1px solid #000000';          # light gray
    has $.border-left       = '1px solid #000000';          # light gray
    has $.border-right      = '1px solid #000000';          # light gray
    has $.border-top        = '1px solid #000000';          # light gray
    has $.color             = '#000000';                    # black
    has $.font-family       = 'arial, verdana, sans-serif';
    has $.font-size         = 10;                           # points
    has $.font-weight       = 400;                          # normal (400/1000)
    has $.margin            = 0;                            # pixels
    has $.padding-bottom    = 0;                            # pixels
    has $.padding-left      = 0;                            # pixels
    has $.padding-right     = 0;                            # pixels
    has $.padding-top       = 0;                            # pixels

    method generate () {
        my $style           = ' ' x $indentation-level;
        $style             ~= '<style>.table-row {';
        $style             ~= ' background-color: ' ~ self.even-background-color            ~ ';';
        $style             ~= ' border-bottom: '    ~ self.border-bottom                    ~ ';';
        $style             ~= ' border-left: '      ~ self.border-left                      ~ ';';
        $style             ~= ' border-right: '     ~ self.border-right                     ~ ';';
        $style             ~= ' border-top: '       ~ self.border-top                       ~ ';';
        $style             ~= ' color: '            ~ self.color                            ~ ';';
        $style             ~= ' font-family: '      ~ self.font-family                      ~ ';';
        $style             ~= ' font-size: '        ~ self.font-size                        ~ 'pt;';
        $style             ~= ' font-weight: '      ~ self.font-weight                      ~ ';';
        $style             ~= ' margin: '           ~ self.margin                           ~ 'px;';
        $style             ~= ' padding-bottom: '   ~ self.padding-bottom                   ~ 'px;';
        $style             ~= ' padding-left: '     ~ self.padding-left                     ~ 'px;';
        $style             ~= ' padding-right: '    ~ self.padding-right                    ~ 'px;';
        $style             ~= ' padding-top: '      ~ self.padding-top                      ~ 'px;';
        $style             ~= ' }</style>';
        return $style;
    }
}

method HTML-print {
    put self.to-html;
}

method to-html {
    my $html = q:to/ENDOFHTMLHEAD/;
    <!DOCTYPE html>
    <html>
        <head>
            <meta http-equiv="Content-Type" content="text/html; charset=us-ascii">
            <style>
                table, h1, th, td {
                    margin-left: auto; 
                    margin-right: auto;
                    padding: 5px;
                    text-align: center;
                }
                th, td {
                    border-bottom: 1px solid #ddd;
                }
                tr:hover {background-color: coral; }
                body {
                    color: #222;
                    background: #fff;
                    font: 100% system-ui;
                }
                a {
                    color: #0033cc;
                }
                @media (prefers-color-scheme: dark) {
                    body {
                        color: #eee;
                        background: #121212;
                    }
                    body a {
                        color: #809fff;
                    }
                }
            </style>
        </head>
    ENDOFHTMLHEAD
    $html ~= ' ' x 4 ~ '<body>' ~ "\n";
    $html ~= ' ' x 8 ~ '<h1>' ~ self.title ~ '</h1>' ~ "\n" if self.title;
    $html ~= ' ' x 8 ~ '<table>' ~ "\n";
    $html ~= ' ' x 12 ~ '<tr>' ~ "\n";
    for $!body.headings.list -> $heading {
        $html ~= ' ' x 16 ~ '<th>' ~ self!subst-ml-text($heading.TEXT) ~ '</th>' ~ "\n";
    }
    $html ~= ' ' x 12 ~ '</tr>' ~ "\n";
    for $!body.meta<sort-order>.list -> $row {
        $html ~= ' ' x 12 ~ '<tr>' ~ "\n";
        loop (my $col = 0; $col < $!body.cells[$row].elems; $col++) {
            $html ~= ' ' x 16 ~ '<td style="';
            if $!body.cells[$row][$col] ~~ Our::Grid::Cell:D {
                given $!body.cells[$row][$col] {
                    if .justification {
                        when 'left'     { $html ~= 'text-align: left;';    }
                        when 'center'   { $html ~= 'text-align: center;';  }
                        when 'right'    { $html ~= 'text-align: right;';   }
                    }
                    loop (my $f = 0; $f < .fragments.elems; $f++) {
                        if .fragments[$f].foreground {
                            $html ~= ' color:'     ~ .fragments[$f].foreground ~ ';';
                            last;
                        }
                    }
                    my $background = '';
                    loop ($f = 0; $f < .fragments.elems; $f++) {
                        if .fragments[$f].background {
                            $background = .fragments[$f].background;
                            $html ~= ' background-color:' ~ $background   ~ ';';
                            last;
                        }
                    }
                    $html ~= ' background-color:'  ~ .highlight    ~ ';'   if !$background && .highlight;
                    $html ~= '"';
                }
                $html ~= '>' ~ self!subst-ml-text($!body.cells[$row][$col].TEXT);
            }
            else {
                $html ~= '">';
            }
            $html ~= '</td>' ~ "\n";
        }
        $html ~= ' ' x 12 ~ '</tr>' ~ "\n";
    }
    $html ~= ' ' x 8 ~ '</table>' ~ "\n";
    $html ~= ' ' x 4 ~ '</body>' ~ "\n";
    $html ~= '</html>';
    return $html;
}

method !subst-ml-text (Str:D $s) {
    my $result  = $s;
    $result     = $result.subst('<', '&lt;',    :g);
    $result     = $result.subst('>', '&gt;',    :g);
    $result     = $result.subst('&', '&amp;',   :g);
    $result     = $result.subst("'", '&apos;',  :g);
    $result     = $result.subst('"', '&quot;',  :g);
    return $result;
}

=finish

<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=us-ascii">
        <title>ISP Sessions</title>
        <style>.paragraph-heading   { font-size: 12pt; font-family: arial, verdana, sans-serif; background-color:#009CDE; font-weight: bold; border: 1px solid #9fabbb; margin-bottom: 5px; padding-left: 9px; padding-right: 10px; padding-top: 1px; padding-bottom: 1px }</style>
        <style>.tabhead     { font-size: 11pt; color: #000000; font-family: arial, verdana, sans-serif; background-color: #d0d0d0; font-weight: bold; border-left: 0px solid #cccccc; border-right: 1px solid #cccccc; border-top: 0px solid #cccccc; border-bottom: 1px solid #cccccc; margin: 0px; padding-left: 5px; padding-right: 5px; padding-top: 0px; padding-bottom: 1px }</style>
        <style>.tabeven     { font-size: 9pt; color: #000000; font-family: arial, verdana, sans-serif; background-color: #f0f0f0; border-left: 0px solid #cccccc; border-right: 1px solid #cccccc; border-top: 0px solid #cccccc; border-bottom: 1px solid #cccccc; margin: 0px; padding-left: 5px; padding-right: 5px; padding-top: 0px; padding-bottom: 1px }</style>
        <style>.tabodd      { font-size: 9pt; color: #000000; font-family: arial, verdana, sans-serif; background-color: white; border-left: 0px solid #cccccc; border-right: 1px solid #cccccc; border-top: 0px solid #cccccc; border-bottom: 1px solid #cccccc; margin: 0px; padding-left: 5px; padding-right: 5px; padding-top: 0px; padding-bottom: 1px }</style>
        <style>.button      { font-size: 10pt; color: #000000; font-family: arial, verdana, sans-serif; background-color: #009CDE; border-left: 1px solid #000000; border-right: 1px solid #000000; border-top: 1px solid #000000; border-bottom: 1px solid #000000; margin: 0px; padding-left: 0px; padding-right: 0px; padding-top: 0px; padding-bottom: 0px } </style>

        <script type="text/javascript">
            function toggleall(parm){ var x = document.getElementsByName('togsection'); var i;for (i = 0; i < x.length; i++) { x[i].style.display =  parm;}}
            function toggle(id){ var n = document.getElementById(id); n.style.display =  (n.style.display!='none' ? 'none' : '' ); }
        </script>
    </head>
    <body style="font-size: 8pt">


<p align="center"><font size="4"><b>ISP status for ISPLC01 at 3/21/2024 8:05:51 AM</b></font></p>
<button class=but onclick="toggleall('');"> Show all </button>   <button class=but onclick="toggleall('none');"> Hide all </button>

<div class=parahead><button class=button onclick="toggle('3');">Show/Hide</button>The following filespaces have not completed their backup within the last 3 days :</div>

<div id="3" name="togsection">



        <br>
        <div class="paragraph-heading">ISPLC01 : 7 Day Summary</div>
        <br>
        <table cellspacing="0" cellpadding="3" bgcolor="#FFFFFF" border="1" width="100%">
            <tr>
                <td class="tabhead"></td>
                <td class="tabhead">5 Mar 24</td>
                <td class="tabhead">6 Mar 24</td>
                <td class="tabhead">7 Mar 24</td>
                <td class="tabhead">8 Mar 24</td>
                <td class="tabhead">9 Mar 24</td>
                <td class="tabhead">10 Mar 24</td>
                <td class="tabhead">11 Mar 24</td>
            </tr>
            <tr>
                <td class="tabeven">ISPLC01  - Number of nodes</td>
                <td class="tabeven">237</td>
                <td class="tabeven">237</td>
                <td class="tabeven">237</td>
                <td class="tabeven">237</td>
                <td class="tabeven">237</td>
                <td class="tabeven">237</td>
                <td class="tabeven"></td>
            </tr>
            <tr>
                <td class="tabodd">ISPLC01  - Total daily backup amount (GB)</td>
                <td class="tabodd">3.1 TB</td>
                <td class="tabodd">2.5 TB</td>
                <td class="tabodd">2.7 TB</td>
                <td class="tabodd">2.7 TB</td>
                <td class="tabodd">2.4 TB</td>
                <td class="tabodd">725.7 GB</td>
                <td class="tabodd"></td>
            </tr>
            <tr>
                <td class="tabeven">ISPLC01  - Total daily restore amount (GB)</td>
                <td class="tabeven">0.0 B</td>
                <td class="tabeven">0.0 B</td>
                <td class="tabeven">0.0 B</td>
                <td class="tabeven">0.0 B</td>
                <td class="tabeven">0.0 B</td>
                <td class="tabeven">0.0 B</td>
                <td class="tabeven"></td>
            </tr>
            <tr>
                <td class="tabodd">ISPLC01  - Total files stored</td>
                <td class="tabodd">471230128</td>
                <td class="tabodd">470920826</td>
                <td class="tabodd">470075221</td>
                <td class="tabodd">469786464</td>
                <td class="tabodd">469895972</td>
                <td class="tabodd">469579526</td>
                <td class="tabodd"></td>
            </tr>
            <tr>
                <td class="tabeven"> ISPLC01  - Total node disk capacity (GB)</td>
                <td class="tabeven"> 12307690</td>
                <td class="tabeven"> 12307690</td>
                <td class="tabeven"> 12307690</td>
                <td class="tabeven"> 12307690</td>
                <td class="tabeven"> 12307690</td>
                <td class="tabeven"> 12307690</td>
                <td class="tabeven"> </td></tr>
            <tr>
                <td class="tabodd"> ISPLC01  - Total rep. ISP space used (GB)</td>
                <td class="tabodd"> 677499</td>
                <td class="tabodd"> 678520</td>
                <td class="tabodd"> 678489</td>
                <td class="tabodd"> 679681</td>
                <td class="tabodd"> 676890</td>
                <td class="tabodd"> 677855</td>
                <td class="tabodd"> </td></tr>
            <tr>
                <td class="tabeven"> ISPLC01  - Total schedule success rate</td>
                <td class="tabeven"> 93</td>
                <td class="tabeven"> 93</td>
                <td class="tabeven"> 91</td>
                <td class="tabeven"> 91</td>
                <td class="tabeven"> 91</td>
                <td class="tabeven"> 85</td>
                <td class="tabeven"></td>
            </tr>
        </table>
      </div>
    </body>
</html>
