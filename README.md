[![Actions Status](https://github.com/lizmat/hide-methods/workflows/test/badge.svg)](https://github.com/lizmat/hide-methods/actions)

NAME
====

hide-methods - hide methods of classes during runtime

SYNOPSIS
========

```raku
use hide-methods;

class A {
    method foo() { say "foo" }
}

A.foo;  # foo

hide-methods(A,"foo");
A.foo;  # X::Method::NotFound

class B {
    method bar() { say "bar" }
}

B.bar;  # bar

my $vault = B.&hide-methods("bar");
B.bar;  # X::Method::NotFound

$vault.unhide-methods("bar");
B.bar;  # bar
```

DESCRIPTION
===========

`hide-methods` is a module that exports a single subroutine called `hide-methods`. Calling this subroutine with a class and one or more method names, will hide the indicated methods from execution, resulting in either having a `X::Method::NotFound` exception thrown, or a method with the same name called from a parent class (if that doesn't happen to be hidden as well, of course).

Handles standard method call dispatch and the `.can` method on classes. Does **not** affect dispatch through `.?`, `.+` or `.*`, or listing with the `.^methods` method.

SUBROUTINES
===========

hide-methods
------------

    hide-methods(A,<foo bar baz>);   # hide "foo","bar","baz" methods in A
    A.&hide-methods(<foo bar baz>);  # same, using method syntax

    my $vault = hide-methods(B,"zippo");  # allow unhiding

    $vault.unhide-methods("zippo");  # make B.zippo available again

The `hide-methods` subroutine takes a class as the first parameter, and one or more names of methods to hide. It returns a `Vault` object that supports a `unhide-methods` method, that takes the names of the methods that should become available again.

AUTHOR
======

Elizabeth Mattijsen <liz@raku.rocks>

Source can be located at: https://github.com/lizmat/hide-methods . Comments and Pull Requests are welcome.

COPYRIGHT AND LICENSE
=====================

Copyright 2020, 2021 Elizabeth Mattijsen

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

