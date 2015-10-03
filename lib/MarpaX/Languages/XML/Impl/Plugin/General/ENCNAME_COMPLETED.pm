use Moops;

# PODCLASSNAME

# ABSTRACT: ENCNAME_COMPLETED Grammar Event implementation

class MarpaX::Languages::XML::Impl::Plugin::General::ENCNAME_COMPLETED {
  use Encode qw/encode/;
  use MarpaX::Languages::XML::Impl::ImmediateAction::Constant;
  use MarpaX::Languages::XML::Impl::Plugin;
  use MarpaX::Languages::XML::Type::PluggableConstant -all;
  use MarpaX::Languages::XML::Type::Context -all;
  use MarpaX::Languages::XML::Type::Dispatcher -all;
  use MarpaX::Languages::XML::Type::Parser -all;
  use MooX::Role::Logger;
  use MooX::Role::Pluggable::Constants;
  use Throwable::Factory
    EncodingException => [qw/$encname/];

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
    # This has a cost but happens only once
    #
    my $encnameId = $context->grammar->compiledGrammar->symbol_by_name_hash->{'_ENCNAME'};
    my $encname = $parser->get_lastLexeme($encnameId);
    #
    # _ENCNAME matches only ASCII characters, so uc() is ok
    #
    my $io = $parser->io;
    if (uc($encname) ne $io->encodingName) {
      $self->_logger->tracef('XML says encoding %s while IO is currently using %s', $encname, $parser->io->encodingName);
      #
      # Check this is a supported encoding trying on a fake string that can never fail
      #
      try {
        my $string = 'abcd';
        my $octets  = encode($encname, $string, Encode::FB_CROAK);
        $self->_logger->tracef('Encoding %s is a supported name', $encname);
      } catch {
        EncodingException->throw("Encoding verification failure: $_", encname => $encname);
      };
      $self->_guess($encname);

      $io->encoding($encname);
      $context->restartRecognizer;
      #
      # Say we want to replay this context
      #
      $context->immediateAction(IMMEDIATEACTION_RETURN);
    } else {
      $self->_logger->tracef('XML and IO agree with encoding %s', $encname);
    }

    return EAT_CLIENT;
  }

  with 'MooX::Role::Logger';
}

1;

