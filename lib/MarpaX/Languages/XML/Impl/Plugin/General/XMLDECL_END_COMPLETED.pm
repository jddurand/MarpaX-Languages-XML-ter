use Moops;

# PODCLASSNAME

# ABSTRACT: XMLDECL_END_COMPLETED Grammar Event implementation

class MarpaX::Languages::XML::Impl::Plugin::General::XMLDECL_END_COMPLETED {
  use MarpaX::Languages::XML::Impl::Context;
  use MarpaX::Languages::XML::Impl::ImmediateAction::Constant;
  use MarpaX::Languages::XML::Impl::Plugin;
  use MarpaX::Languages::XML::Type::PluggableConstant -all;
  use MarpaX::Languages::XML::Type::Context -all;
  use MarpaX::Languages::XML::Type::Dispatcher -all;
  use MarpaX::Languages::XML::Type::Parser -all;
  use MooX::Role::Logger;
  use MooX::Role::Pluggable::Constants;

  extends qw/MarpaX::Languages::XML::Impl::Plugin/;

  has '+subscriptions' => (default => sub { return
                                              {
                                               NOTIFY => [ 'XMLDECL_END_COMPLETED' ]
                                              };
                                          }
                          );

  method N_XMLDECL_END_COMPLETED(Dispatcher $dispatcher, Parser $parser, Context $context --> PluggableConstant) {
    #
    # Set the eolHandling flag
    #
    $parser->eolHandling(true);
    #
    # And say that reduce of buffer is allowed
    #
    $parser->canReduce(true);

    return EAT_CLIENT   # No ';' for fewer hops
  }

  with 'MooX::Role::Logger';
}

1;

