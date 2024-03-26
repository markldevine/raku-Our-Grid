sub EXPORT ($MAIN-switches = Nil) {
#sub EXPORT () {
  my %switches =
    "a1" => 'a1',
    "a2" => 2,
    "a3" => 3,
    ;
# %h{$ui} = Terminal::UI.new if $ui;
  %switches;
}


unit class C:api<1>:auth<Mark Devine (mark@markdevine.com)>;

has                 $.a1    = 'default a1';
has                 $.a2    = 'default a2';

submethod TWEAK {
    put 'In class C...';
}

method fields(--> List) {
    #| Return a list of the the attribute names (fields) 
    #| of the class instance 
    my @attributes = self.^attributes;
    my @names;
    for @attributes -> $a {
        my $name = $a.name;
        # The name is prefixed by its sigil and twigil 
        # which we don't want 
        $name ~~ s/\S\S//;
        @names.push: $name;
    }
    @names
}
 
method values(--> List) {
    #| Return a list of the values for the attributes 
    #| of the class instance 
    my @attributes = self.^attributes;
    my @values;
    for @attributes -> $a {
        # Syntax is not obvious 
        my $value = $a.get_value: self;
        @values.push: $value;
    }
    @values
}

=finish
