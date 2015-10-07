use Moops;

# PODCLASSNAME

# ABSTRACT: Well-Formed constraint External Subset

class MarpaX::Languages::XML::Impl::Plugin::WFC::ExternalSubset {
  use IO::All;
  use IO::All::LWP;
  use MarpaX::Languages::XML::Impl::Reader::IO::All;
  use MarpaX::Languages::XML::Impl::Plugin;
  use MarpaX::Languages::XML::Type::PluggableConstant -all;
  use MarpaX::Languages::XML::Type::Context -all;
  use MarpaX::Languages::XML::Type::Dispatcher -all;
  use MarpaX::Languages::XML::Type::Parser -all;
  use MooX::Role::Logger;
  use MooX::Role::Pluggable::Constants;
  use POSIX qw/EXIT_SUCCESS EXIT_FAILURE/;

  extends qw/MarpaX::Languages::XML::Impl::Plugin/;

  has '+doc' => (is => 'ro', default => 'Well-formedness constraint: External Subset');

  has '+subscriptions' => (default => sub { return
                                              {
                                               NOTIFY => [ 'NOT_DQUOTEMANY_COMPLETED', 'NOT_SQUOTEMANY_COMPLETED' ],
                                              };
                                          }
                          );

  my $NOT_DQUOTEMANYId;
  my $NOT_SQUOTEMANYId;

  method DEMOLISH {
    undef $NOT_DQUOTEMANYId;
    undef $NOT_SQUOTEMANYId;
  }

  method _isExternalSubset(Dispatcher $dispatcher, Parser $parser, Context $context, Str $origin, Str $systemLiteral --> PluggableConstant) {
    #
    # Verify it passes the extSubset rule.
    #
    if ($parser->parseByteStream(MarpaX::Languages::XML::Impl::Reader::IO::All->new(io($systemLiteral)), 'extSubset', false) == EXIT_SUCCESS) {
      $self->_logger->tracef('System Literal %s passes the extSubset production', $systemLiteral);
    } else {
      #
      # We will be smart enough to reposition exactly at the beginning of the character reference
      #
      $parser->deltaPosCharBuffer(- length($origin));
      $parser->throw('Parse', $context, "System Literal $origin does not match the extSubset production");
    }

    return EAT_CLIENT;
  }

  method N_NOT_DQUOTEMANY_COMPLETED(Dispatcher $dispatcher, Parser $parser, Context $context --> PluggableConstant) {

    $NOT_DQUOTEMANYId //= $context->grammar->compiledGrammar->symbol_by_name_hash->{'_NOT_DQUOTEMANY'};
    my $systemLiteral = $parser->get_lastLexeme($NOT_DQUOTEMANYId);
    my $origin = "\"$systemLiteral\"";

    return $self->_isExternalSubset($dispatcher, $parser, $context, $origin, $systemLiteral);
  }

  method N_NOT_SQUOTEMANY_COMPLETED(Dispatcher $dispatcher, Parser $parser, Context $context --> PluggableConstant) {

    $NOT_SQUOTEMANYId //= $context->grammar->compiledGrammar->symbol_by_name_hash->{'_NOT_SQUOTEMANY'};
    my $systemLiteral = $parser->get_lastLexeme($NOT_SQUOTEMANYId);
    my $origin = "'$systemLiteral'";

    return $self->_isExternalSubset($dispatcher, $parser, $context, $origin, $systemLiteral);
  }

  with 'MooX::Role::Logger';
}

1;

