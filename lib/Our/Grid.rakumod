unit class Our::Grid:api<1>:auth<Mark Devine (mark@markdevine.com)>;

use Our::Grid::Cell;
use Our::Utilities;

#   ???????????????????????????????????????????????????????????????????
#   ?TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT?
#   ???????????????????????????????????????????????????????????????????
#   ?LLLL?pHHHHHp?pHHHHHp?pHHHHHp?pHHHHHp?pHHHHHp?pHHHHHp?pHHHHHp?RRRR?
#   ?LLLL?p-----p?p-----p?p-----p?p-----p?p-----p?p-----p?p-----p?RRRR?
#   ?LLLL?pAAAAAp?pBBBBBp?pCCCCCp?pDDDDDp?pEEEEEp?pFFFFFp?pGGGGGp?RRRR?
#   ?LLLL?pHHHHHp?pIIIIIp?pKKKKKp?pLLLLLp?pMMMMMp?pNNNNNp?pOOOOOp?RRRR?
#   ?LLLL?pPPPPPp?pQQQQQp?pWWWWWp?pXXXXXp?pYYYYYp?pZZZZZp?p     p?RRRR?
#   ???????????????????????????????????????????????????????????????????
#   fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff

has $.title;
has $.header;
has $.footer;
has $.term-size;

has $.grid          = Array.new();
has $.current-row   = 0;
has $.current-col   = 0;
has @.col-width;

has $.borders;

submethod TWEAK {
    $!term-size     = term-size;                                            # $!term-size.rows $!term-size.cols
}

method add-cell (Our::Grid::Cell:D :$cell, :$row is copy = 0, :$col is copy = 0) {
    given $row {
        when Bool   { ++$!current-row;  $row = $!current-row;                                   }
        when Int    { $!current-row     = $row;                                                 }
    }
    given $col {
        when Bool   { ++$!current-col;  $col = $!current-col                                    }
        when Int    { $!current-col     = $col;                                                 }
        default     { $!current-col     = $!grid[$!current-row].elems; $col = $!current-col;    }
    }
    $!grid[$row]        = Array.new()   unless $!grid[$row];
    @!col-width[$col]   = 0 unless @!col-width[$col];
    @!col-width[$col]   = $cell.TEXT.Str.chars if $cell.TEXT.Str.chars > @!col-width[$col];
    if $col {
        $!grid[$row][$col] = $cell;
    }
    else {
        $!grid[$row].push: $cell;
    }
}

method TEXT-print {

#   probably should default all Any things in the grid at this point...
#   make it only as required; do it once, flag if anything updates, only run it again if an update occurred

    loop (my $row = 0; $row < $!grid.elems; $row++) {
        loop (my $col = 0; $col < $!grid[$row].elems; $col++) {
            print ' ';
            print $!grid[$row][$col].TEXT-padded(:width(@!col-width[$col]));
            print ' ' unless $col == ($!grid[$row].elems - 1);
        }
        print " \n";
    }
}

#| Character Cell Graphics Set
my  %box-char = (
        side                => '│',
        horizontal          => '─',
        down-and-horizontal => '┬', 
        up-and-horizontal   => '┴',
        top-left-corner     => '┌',
        top-right-corner    => '┐',
        bottom-left-corner  => '└',
        bottom-right-corner => '┘',
        side-row-left-sep   => '├',
        side-row-right-sep  => '┤',
    );

method ANSI-print {

#   probably should default all Any things in the grid at this point...


    my $col-width-total = 0;
    for @!col-width -> $colw {
        $col-width-total += $colw;
    }
    $col-width-total   += (@!col-width.elems * 3) - 1;
    my $margin          = ($!term-size.cols - ($col-width-total + 2)) div 2;
    if $!title {
        my $left-pad    = ($col-width-total - $!title.chars) div 2;
        my $right-pad   = $col-width-total - $!title.chars - $left-pad;
        put ' ' x $margin ~ %box-char<top-left-corner> ~ %box-char<horizontal> x $col-width-total ~ %box-char<top-right-corner>;
        put ' ' x $margin ~ %box-char<side> ~ ' ' x $left-pad ~ $!title ~ ' ' x $right-pad ~ %box-char<side>;

        print ' ' x $margin ~ %box-char<side-row-left-sep>;
        loop (my $i = 0; $i < (@!col-width.elems - 1); $i++) {
            print %box-char<horizontal> x (@!col-width[$i] + 2) ~ %box-char<down-and-horizontal>;
        }
        put %box-char<horizontal> x (@!col-width[*-1] + 2) ~ %box-char<side-row-right-sep>;
    }
    else {
        print ' ' x $margin ~ %box-char<top-left-corner>;
        loop (my $i = 0; $i < (@!col-width.elems - 1); $i++) {
            print %box-char<horizontal> x (@!col-width[$i] + 2) ~ %box-char<down-and-horizontal>;
        }
        put %box-char<horizontal> x (@!col-width[*-1] + 2) ~ %box-char<top-right-corner>;
    }
    loop (my $row = 0; $row < $!grid.elems; $row++) {
        print ' ' x $margin;
        loop (my $col = 0; $col < $!grid[$row].elems; $col++) {
            print %box-char<side> ~ ' ';
            print $!grid[$row][$col].ANSI-fmt(:width(@!col-width[$col])).ANSI-padded with $!grid[$row][$col];
            print ' ' unless $col == ($!grid[$row].elems - 1);
        }
        put ' ' ~ %box-char<side>;
    }
    print ' ' x $margin ~ %box-char<bottom-left-corner>;
    loop (my $i = 0; $i < (@!col-width.elems - 1); $i++) {
        print %box-char<horizontal> x (@!col-width[$i] + 2) ~ %box-char<up-and-horizontal>;
    }
    put %box-char<horizontal> x (@!col-width[*-1] + 2) ~ %box-char<bottom-right-corner>;
}

=finish
