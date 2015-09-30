use Moops;

# PODCLASSNAME

# ABSTRACT: content_NULLED Grammar Event implementation

class MarpaX::Languages::XML::Impl::Plugin::General::content_NULLED {
  use MarpaX::Languages::XML::Impl::Context;
  use MarpaX::Languages::XML::Impl::ImmediateAction::Constant;
  use MarpaX::Languages::XML::Impl::Plugin;
  use MarpaX::Languages::XML::Type::PluggableConstant -all;
  use MarpaX::Languages::XML::Type::Context -all;
  use MarpaX::Languages::XML::Type::Dispatcher -all;
  use MarpaX::Languages::XML::Type::Parser -all;
  use MooX::Role::Logger;
  use MooX::Role::Pluggable::Constants;
  use Types::Common::Numeric -all;

  extends qw/MarpaX::Languages::XML::Impl::Plugin/;

  has '+subscriptions' => (default => sub { return
                                              {
                                               NOTIFY => [ 'content_NULLED' ]
                                              };
                                          }
                          );

  has _etag_start_length => ( is => 'rw', isa => PositiveOrZeroInt, predicate => 1);
  has _etag_start_regexp => ( is => 'rw', isa => RegexpRef, predicate => 1);

  method N_content_NULLED(Dispatcher $dispatcher, Parser $parser, Context $context --> PluggableConstant) {
    #
    # If the next characters do match ETAG_START then the content is over.
    # The only complication is because we are working in streaming mode
    #
    my $pos       = pos($MarpaX::Languages::XML::Impl::Parser::buffer);
    my $length    = length($MarpaX::Languages::XML::Impl::Parser::buffer);
    my $remaining = $length - $pos;
    my $etag_start_length;
    if (! $self->_has_etag_start_length) {
      $etag_start_length = $self->_etag_start_length($context->grammar->get_lexemesMinlength('_ETAG_START'));
    } else {
      $etag_start_length = $self->_etag_start_length;
    }
    my $etag_start_regexp;
    if (! $self->_has_etag_start_regexp) {
      $etag_start_regexp = $self->_etag_start_regexp($context->grammar->get_lexemesRegexp('_ETAG_START'));
    } else {
      $etag_start_regexp = $self->_etag_start_regexp;
    }
    my $match;
    if ($etag_start_length <= $remaining ) {
      #
      # We can safely say if it matches or not
      #
      $match = ($MarpaX::Languages::XML::Impl::Parser::buffer =~ $etag_start_regexp);
    } else {
      if (! $parser->eof) {
        my $needed = $etag_start_length - $remaining;
        $self->_logger->tracef('%s Undecidable: need at least %d characters more', 'ETAG_START', $etag_start_length);
        my $io = $parser->io;
        my $old_block_size_value = $io->block_size_value;
        if ($old_block_size_value != $needed) {
          $io->block_size($needed);
        }
        $parser->read($dispatcher, $context);
        if ($old_block_size_value != $needed) {
          $io->block_size($old_block_size_value);
        }
        pos($MarpaX::Languages::XML::Impl::Parser::buffer) = $pos;
        my $new_length = length($MarpaX::Languages::XML::Impl::Parser::buffer);
        if ($new_length > $length) {
          #
          # Something was read
          #
          $match = ($MarpaX::Languages::XML::Impl::Parser::buffer =~ $etag_start_regexp);
        } else {
          $self->eof(true);
          $match = false;
        }
      } else {
        $match = false;
      }
    }
    if ($match) {
      $context->immediateAction(IMMEDIATEACTION_STOP);
      #
      # It is impossible to not have another context upper
      #
      $context->parentContext->immediateAction(IMMEDIATEACTION_RESUME);
    }

    return EAT_CLIENT   # No ';' for fewer hops
  }

  with 'MooX::Role::Logger';
}

1;

