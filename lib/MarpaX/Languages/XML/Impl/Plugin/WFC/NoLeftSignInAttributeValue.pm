use Moops;

# PODCLASSNAME

# ABSTRACT: Well-Formed constraint "No < sign in attribute value" implementation

class MarpaX::Languages::XML::Impl::Plugin::WFC::NoLeftSignInAttributeValue :assertions {
  use MarpaX::Languages::XML::Impl::Plugin;
  use MarpaX::Languages::XML::Type::PluggableConstant -all;
  use MarpaX::Languages::XML::Type::State -all;
  use MooX::Role::Logger;
  use MooX::Role::Pluggable::Constants;

  extends qw/MarpaX::Languages::XML::Impl::Plugin/;

  has '+subscriptions' => (default => sub { return
                                              {
                                               NOTIFY => [ 'AttValue_COMPLETED' ]
                                              };
                                          }
                          );

  method N_AttValue_COMPLETE(Dispatcher $dispatcher, State $state --> PluggableConstant) {
    return EAT_CLIENT   # No ';' for fewer hops
  }

  with 'MooX::Role::Logger';
}

1;

