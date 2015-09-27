use Moops;

# PODCLASSNAME

# ABSTRACT: ENCNAME_COMPLETED Grammar Event implementation

class MarpaX::Languages::XML::Impl::Grammar::Event::ENCNAME_COMPLETED :assertions {
  use MarpaX::Languages::XML::Impl::Plugin;
  use MarpaX::Languages::XML::Type::PluggableConstant -all;
  use MarpaX::Languages::XML::Type::State -all;
  use MooX::Role::Logger;
  use MooX::Role::Pluggable::Constants;

  extends qw/MarpaX::Languages::XML::Impl::Plugin/;

  has '+subscriptions' => (default => sub { return
                                              {
                                               NOTIFY => [ 'ENCNAME_COMPLETED' ]
                                              };
                                          }
                          );

  method N_ENCNAME_COMPLETE(Dispatcher $dispatcher, State $state --> PluggableConstant) {
    return EAT_CLIENT   # No ';' for fewer hops
  }

  with 'MarpaX::Languages::XML::Role::Plugin';
  with 'MooX::Role::Logger';
}

1;

