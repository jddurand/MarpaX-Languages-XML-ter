use Moops;

# PODCLASSNAME

# ABSTRACT: STag_COMPLETED Grammar Event implementation

class MarpaX::Languages::XML::Impl::Plugin::General::STag_COMPLETED {
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
                                               NOTIFY => [ 'STag_COMPLETED' ]
                                              };
                                          }
                          );

  method N_STag_COMPLETED(Dispatcher $dispatcher, Parser $parser, Context $context --> PluggableConstant) {
    #
    # Push content context in any case
    #
    my $newContext = MarpaX::Languages::XML::Impl::Context->new(
                                                                grammar          => $parser->get_grammar('content'),
                                                                endEventName     => $parser->get_grammar_endEventName('content'),
                                                                line             => $context->line,
                                                                column           => $context->column,
                                                                parentContext    => $context,
                                                               );
    $parser->_push_context($newContext);
    #
    # We are pushing a nullable, this is why it is ok to say stop for a further resume
    #
    $context->immediateAction(IMMEDIATEACTION_PAUSE);

    return EAT_CLIENT   # No ';' for fewer hops
  }

  with 'MooX::Role::Logger';
}

1;

