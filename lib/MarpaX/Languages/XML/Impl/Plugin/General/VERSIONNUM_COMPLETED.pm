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
    # This has a cost but happens only once.
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
      # Make sure IO is resetted
      #
      $parser->io->reopen;
      #
      # And replace context elements
      #
      $context->set_grammar($parser->get_grammar($context->grammar->startSymbol));
      $context->set_endEventName($parser->get_grammar_endEventName($context->grammar->startSymbol));
      $context->immediateAction(IMMEDIATEACTION_RETURN);
    } else {
      $self->_logger->tracef('XML and Grammar agree with version number %s', $versionnum);
    }

    return EAT_CLIENT;
  }

  with 'MooX::Role::Logger';
}

1;

