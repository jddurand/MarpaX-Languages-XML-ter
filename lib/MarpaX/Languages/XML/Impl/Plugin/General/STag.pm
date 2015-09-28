use Moops;

# PODCLASSNAME

# ABSTRACT: STag Grammar Event implementation

class MarpaX::Languages::XML::Impl::Plugin::General::STag {
  use MarpaX::Languages::XML::Impl::Context;
  use MarpaX::Languages::XML::Impl::Plugin;
  use MarpaX::Languages::XML::Type::PluggableConstant -all;
  use MarpaX::Languages::XML::Type::Context -all;
  use MarpaX::Languages::XML::Type::Dispatcher -all;
  use MarpaX::Languages::XML::Type::Parser -all;
  use MooX::Role::Pluggable::Constants;

  extends qw/MarpaX::Languages::XML::Impl::Plugin/;

  has '+subscriptions' => (default => sub { return
                                              {
                                               NOTIFY => [ 'STag_COMPLETED' ]
                                              };
                                          }
                          );

  method N_STag_COMPLETED(Dispatcher $dispatcher, Parser $parser, Context $context --> PluggableConstant) {
    $parser->_logger->tracef('STag_COMPLETED event, number of remaining context is %d', $parser->_count_contexts);
    my $newContext = MarpaX::Languages::XML::Impl::Context->new(
                                                                io               => $context->io,
                                                                grammar          => $parser->_get_grammar('content'),
                                                                encoding         => $context->encoding,
                                                                dispatcher       => $dispatcher,
                                                                namespaceSupport => $context->namespaceSupport,
                                                                endEventName     => 'content_COMPLETED',
                                                                demolish         => $parser->_get_grammar_demolish('content'),
                                                                build            => $parser->_get_grammar_build('content')
                                                               );
    $parser->_push_context($newContext);
    return EAT_CLIENT   # No ';' for fewer hops
  }

}

1;

