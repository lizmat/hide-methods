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

# vim: expandtab shiftwidth=4
