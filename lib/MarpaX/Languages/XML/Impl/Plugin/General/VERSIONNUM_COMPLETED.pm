use Moops;

# PODCLASSNAME

# ABSTRACT: VERSIONNUM_COMPLETED Grammar Event implementation

class MarpaX::Languages::XML::Impl::Plugin::General::VERSIONNUM_COMPLETED {
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
                                               NOTIFY => [ 'VERSIONNUM_COMPLETED' ]
                                              };
                                          }
                          );

  method N_VERSIONNUM_COMPLETED(Dispatcher $dispatcher, Parser $parser, Context $context --> PluggableConstant) {
    #
    # Get declared version number
    #
    my $versionnumId = $context->grammar->compiledGrammar->symbol_by_name_hash->{'_VERSIONNUM'};
    my $versionnum = $parser->get_lastLexeme($versionnumId);
    if ($versionnum ne $context->grammar->xmlVersion) {
      $self->_logger->tracef('XML says version number %s while grammar is currently using %s', $versionnum, $context->grammar->xmlVersion);
      #
      # Look to Parser's xmlVersion implementation: it will call clearers
      #
      $parser->xmlVersion($versionnum);
      #
      # Per def we are at first and only context
      #
      $parser->set_context(0,
                           MarpaX::Languages::XML::Impl::Context->new(
                                                                      grammar          => $parser->get_grammar($context->grammar->startSymbol),
                                                                      endEventName     => $parser->get_grammar_endEventName($context->grammar->startSymbol),
                                                                      immediateAction  => IMMEDIATEACTION_RESTART
                                                                     )
                          );
      #
      # Make sure IO is resetted as well. Setting the encoding will do it.
      #
      $parser->io->reopen;
      #
      # And say to restart (Caller is still using the old context pointer)
      #
      # Not needed
      # $context->restartRecognizer;
      $context->immediateAction(IMMEDIATEACTION_RESTART);
    } else {
      $self->_logger->tracef('XML and Grammar agree with version number %s', $versionnum);
    }

    return EAT_CLIENT   # No ';' for fewer hops
  }

  with 'MooX::Role::Logger';
}

1;

