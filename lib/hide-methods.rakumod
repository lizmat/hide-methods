my %classes{Mu};       # a hash keyed to the actual type objects
my $lock := Lock.new;  # a lock for concurrent access / updates

# marker for methods wrapped here
my role MethodWrapped {
    has $.hidden is rw;
    method is-hidden-from-backtrace(--> True) { }
}

# class for keeping deleted methods information
my class MethodVault {
    has $!class is built;

    # revive given methods for class of this object
    method unhide-methods(MethodVault:D: *@names) {
        $lock.protect: {
            if %classes{$!class}:exists {
                my %wrapped := %classes{$!class};
                for @names -> $name {
                    if $!class.^find_method($name) -> $method {
                        with %wrapped{$name}:delete {
                            $method.unwrap($_);
                            $method.hidden = False;
                        }
                    }
                }
            }
        }
    }
}

# sub for runtime hiding of methods
my sub hide-methods(Mu:U $class, *@methods --> MethodVault:D) is export {
    $lock.protect: {
        my %wrapped := %classes{$class}:exists
          ?? %classes{$class}
          !! (%classes{$class} := {});

        for @methods -> $name {
            my $method := $class.^find_method($name);
            unless $method ~~ MethodWrapped {

                sub wrapper(\SELF, |c) is hidden-from-backtrace {
                    # cannot use nextcallee because that would refer
                    # to the original method that got wrapped.
                    my $type := $class.^mro[1];
                    if $type.^find_method('can')($type,$name).head -> &nextone {
                        nextone(SELF, |c)
                    }
                    else {
                        X::Method::NotFound.new(
                            method   => $name,
                            typename => SELF.^name,
                        ).throw
                    }
                }
                $method does MethodWrapped;
                $method.hidden = True;

                %wrapped{$name} := $method.wrap(&wrapper);
            }
        }

        sub can-wrapper(Mu:U $class is raw, Str:D $name) {
            $class.^can($name).grep({
                $_ !~~ MethodWrapped || !.hidden
            }).List
        }

        unless $class.^find_method("can").package =:= &can-wrapper.package {
            $class.^add_method("can",&can-wrapper);
            $class.^compose;
        }

        MethodVault.new(:$class)
    }
}

=begin pod

=head1 NAME

hide-methods - hide methods of classes during runtime

=head1 SYNOPSIS

=begin code :lang<raku>

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

=end code

=head1 DESCRIPTION

C<hide-methods> is a module that exports a single subroutine called
C<hide-methods>.  Calling this subroutine with a class and one or more
method names, will hide the indicated methods from execution, resulting
in either having a C<X::Method::NotFound> exception thrown, or a method
with the same name called from a parent class (if that doesn't happen
to be hidden as well, of course).

Handles standard method call dispatch and the C<.can> method on classes.
Does B<not> affect dispatch through C<.?>, C<.+> or C<.*>, or listing
with the C<.^methods> method.

=head1 SUBROUTINES

=head2 hide-methods

=begin code :lang<raku>

hide-methods(A,<foo bar baz>);   # hide "foo","bar","baz" methods in A
A.&hide-methods(<foo bar baz>);  # same, using method syntax

my $vault = hide-methods(B,"zippo");  # allow unhiding

$vault.unhide-methods("zippo");  # make B.zippo available again

=end code

The C<hide-methods> subroutine takes a class as the first parameter, and
one or more names of methods to hide.  It returns a C<Vault> object that
supports a C<unhide-methods> method, that takes the names of the methods
that should become available again.

=head1 AUTHOR

Elizabeth Mattijsen <liz@raku.rocks>

Source can be located at: https://github.com/lizmat/hide-methods . Comments and
Pull Requests are welcome.

If you like this module, or what I'm doing more generally, committing to a
L<small sponsorship|https://github.com/sponsors/lizmat/>  would mean a great
deal to me!

=head1 COPYRIGHT AND LICENSE

Copyright 2020, 2021, 2024 Elizabeth Mattijsen

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
