use Test;
use hide-methods;

plan 27;

my int $called-A-bar;
my int $called-B-bar;
sub reset-called() {
    $called-A-bar = $called-B-bar = 0;
}

class A {
    method bar() { ++$called-A-bar }
}

class B is A {
    method bar() { ++$called-B-bar }
}

A.bar;
is $called-A-bar, 1, 'did A.bar get called';
is $called-B-bar, 0, 'did B.bar **not** get called';

reset-called;
B.bar;
is $called-A-bar, 0, 'did A.bar **not** get called';
is $called-B-bar, 1, 'did B.bar get called';

my $vaultB = B.&hide-methods(<bar>);
ok $vaultB.defined, 'did we get an instantiated vault for B';

reset-called;
lives-ok { B.bar }, 'can we call B.bar';
is $called-A-bar, 1, 'did A.bar get called';
is $called-B-bar, 0, 'did B.bar **not** get called';

is B.can("bar").elems, 1, 'is there only candidate left';

my $vaultA = A.&hide-methods(<bar>);
ok $vaultA.defined, 'did we get an instantiated vault for A';
is A.can("bar").elems, 0, 'there are no candidates left in A';
is B.can("bar").elems, 0, 'there are no candidates left in B';

throws-like { A.bar }, X::Method::NotFound,
  typename => "A",
  method   => "bar",
  'could A.bar not be found now';
throws-like { B.bar }, X::Method::NotFound,
  typename => "B",
  method   => "bar",
  'could B.bar not be found now';

$vaultB.unhide-methods("bar");
is A.can("bar").elems, 0, 'still no candidates left in A';
is B.can("bar").elems, 1, 'one candidate in B again';

reset-called;
lives-ok { B.bar }, 'can call B.bar again';
is $called-A-bar, 0, 'did A.bar **not** get called';
is $called-B-bar, 1, 'did B.bar get called';

$vaultA.unhide-methods("bar");
is A.can("bar").elems, 1, 'one candidates in A again';
is B.can("bar").elems, 2, 'two candidates in B again';

reset-called;
lives-ok { A.bar }, 'can call A.bar again';
is $called-A-bar, 1, 'did A.bar get called';
is $called-B-bar, 0, 'did B.bar **not** get called';

reset-called;
lives-ok { B.bar }, 'can call B.bar again';
is $called-A-bar, 0, 'did A.bar **not** get called';
is $called-B-bar, 1, 'did B.bar get called';
