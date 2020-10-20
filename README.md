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

AUTHOR
======

Elizabeth Mattijsen <liz@wenzperl.nl>

Source can be located at: https://github.com/lizmat/hide-methods . Comments and Pull Requests are welcome.

COPYRIGHT AND LICENSE
=====================

Copyright 2020 Elizabeth Mattijsen

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

