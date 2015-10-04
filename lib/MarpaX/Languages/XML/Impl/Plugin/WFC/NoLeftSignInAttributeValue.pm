use Moops;

# PODCLASSNAME

# ABSTRACT: Well-Formed constraint "No < sign in attribute value" implementation

class MarpaX::Languages::XML::Impl::Plugin::WFC::NoLeftSignInAttributeValue {
  use MarpaX::Languages::XML::Impl::Plugin;
  use MarpaX::Languages::XML::Type::PluggableConstant -all;
  use MarpaX::Languages::XML::Type::Context -all;
  use MarpaX::Languages::XML::Type::Dispatcher -all;
  use MarpaX::Languages::XML::Type::Parser -all;
  use MooX::Role::Logger;
  use MooX::Role::Pluggable::Constants;

  extends qw/MarpaX::Languages::XML::Impl::Plugin/;

  has '+doc' => (is => 'ro', default => 'Well-formedness constraint: No < in Attribute Values');

  has '+subscriptions' => (default => sub { return
                                              {
                                               NOTIFY => [ 'AttValue_COMPLETED' ]
                                              };
                                          }
                          );

  method N_AttValue_COMPLETE(Dispatcher $dispatcher, Parser $parser, Context $context --> PluggableConstant) {
    return EAT_CLIENT   # No ';' for fewer hops
  }

  with 'MooX::Role::Logger';
}

1;

