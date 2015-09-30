use Moops;

# PODCLASSNAME

# ABSTRACT: ENCNAME_COMPLETED Grammar Event implementation

class MarpaX::Languages::XML::Impl::Plugin::General::ENCNAME_COMPLETED {
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
                                               NOTIFY => [ 'ENCNAME_COMPLETED' ]
                                              };
                                          }
                          );

  method N_ENCNAME_COMPLETED(Dispatcher $dispatcher, Parser $parser, Context $context --> PluggableConstant) {
    #
    # Get declared encoding
    #
    my $encnameId = $context->grammar->compiledGrammar->symbol_by_name_hash->{'_ENCNAME'};
    my $encname = $parser->get_lastLexeme($encnameId);
    #
    # _ENCNAME matches only ASCII characters, so uc() is ok
    #
    my $io = $parser->io;
    if (uc($encname) ne $io->encodingName) {
      $self->_logger->tracef('XML says encoding %s while IO is currently using %s', $encname, $parser->io->encodingName);
      $io->pos(0);
      $io->clear;
      $io->encoding($encname);
      $context->restartRecognizer;
      $context->immediateAction(IMMEDIATEACTION_RESTART);
    } else {
      $self->_logger->tracef('XML and IO agree with encoding %s', $encname);
    }

    return EAT_CLIENT   # No ';' for fewer hops
  }

  with 'MooX::Role::Logger';
}

1;

