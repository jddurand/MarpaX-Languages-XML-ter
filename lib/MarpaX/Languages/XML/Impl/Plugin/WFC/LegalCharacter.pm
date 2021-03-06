use Moops;

# PODCLASSNAME

# ABSTRACT: Well-Formed constraint Legal Character

class MarpaX::Languages::XML::Impl::Plugin::WFC::LegalCharacter {
  use MarpaX::Languages::XML::Impl::Reader::Str;
  use MarpaX::Languages::XML::Impl::Plugin;
  use MarpaX::Languages::XML::Type::PluggableConstant -all;
  use MarpaX::Languages::XML::Type::Context -all;
  use MarpaX::Languages::XML::Type::Dispatcher -all;
  use MarpaX::Languages::XML::Type::Parser -all;
  use MooX::Role::Logger;
  use MooX::Role::Pluggable::Constants;
  use POSIX qw/EXIT_SUCCESS EXIT_FAILURE/;

  extends qw/MarpaX::Languages::XML::Impl::Plugin/;

  has '+doc' => (is => 'ro', default => 'Well-formedness constraint: Legal Character');

  has '+subscriptions' => (default => sub { return
                                              {
                                               NOTIFY => [ 'CHARREF_END1_COMPLETED', 'CHARREF_END2_COMPLETED' ],
                                              };
                                          }
                          );

  my $DIGITMANYId;
  my $ALPHAMANYId;

  method DEMOLISH {
    undef $ALPHAMANYId;
    undef $DIGITMANYId;
  }

  method _isChar(Dispatcher $dispatcher, Parser $parser, Context $context, Str $origin, Str $char --> PluggableConstant) {
    #
    # Verify it passes the Char rule.
    #
    if ($parser->parseCharStream(MarpaX::Languages::XML::Impl::Reader::Str->new($char), 'Char', false) == EXIT_SUCCESS) {
      $self->_logger->tracef('Character Reference %s passes the Char production', $origin);
    } else {
      #
      # We will be smart enough to reposition exactly at the beginning of the character reference
      #
      $parser->deltaPosCharBuffer(- length($origin));
      $parser->throw('Parse', $context, "Character Reference $origin does not match the Char production");
    }

    return EAT_CLIENT;
  }

  method N_CHARREF_END1_COMPLETED(Dispatcher $dispatcher, Parser $parser, Context $context --> PluggableConstant) {

    $DIGITMANYId //= $context->grammar->compiledGrammar->symbol_by_name_hash->{'_DIGITMANY'};
    my $DIGITMANY = $parser->get_lastLexeme($DIGITMANYId);
    my $char = chr(int($DIGITMANY));
    my $origin = "&#$DIGITMANY;";

    return $self->_isChar($dispatcher, $parser, $context, $origin, $char);
  }

  method N_CHARREF_END2_COMPLETED(Dispatcher $dispatcher, Parser $parser, Context $context --> PluggableConstant) {
    $ALPHAMANYId //= $context->grammar->compiledGrammar->symbol_by_name_hash->{'_ALPHAMANY'};
    my $ALPHAMANY = $parser->get_lastLexeme($ALPHAMANYId);
    my $char;
    {
      #
      # We do want perl to emit any warning at this stage
      #
      no warnings;
      $char = chr(hex($ALPHAMANY))
    }
    my $origin = "&#x$ALPHAMANY;";

    return $self->_isChar($dispatcher, $parser, $context, $origin, $char);
  }

  with 'MooX::Role::Logger';
}

1;

