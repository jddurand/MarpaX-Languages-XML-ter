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

  our $_ETAG_START = qr{\G</}p;
  our $_ETAG_START_LENGTH = 2;


  extends qw/MarpaX::Languages::XML::Impl::Plugin/;

  has '+subscriptions' => (default => sub { return
                                              {
                                               NOTIFY => [ 'content_NULLED' ]
                                              };
                                          }
                          );

  method N_content_NULLED(Dispatcher $dispatcher, Parser $parser, Context $context --> PluggableConstant) {
    #
    # If the next characters do match ETAG_START then the content is over.
    # The only complication is because we are working in streaming mode.
    # Regardless of the XML version, _ETAG_START is always '</', i.e. two characters,
    # its regexp is always 
    #
    my $pos       = pos($MarpaX::Languages::XML::Impl::Parser::buffer);
    my $length    = length($MarpaX::Languages::XML::Impl::Parser::buffer);
    my $remaining = $length - $pos;
    my $match;
    if ($_ETAG_START_LENGTH <= $remaining ) {
      #
      # We can safely say if it matches or not
      #
      $match = ($MarpaX::Languages::XML::Impl::Parser::buffer =~ $_ETAG_START);
      # print STDERR substr($MarpaX::Languages::XML::Impl::Parser::buffer, $pos, 2) . " =~ $_ETAG_START ? " . ($match ? "yes" : "no") ."\n";
    } else {
      if (! $parser->eof) {
        my $needed = $_ETAG_START_LENGTH - $remaining;
        $self->_logger->tracef('%s Undecidable: need at least %d characters more', 'ETAG_START', $needed);
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
          $match = ($MarpaX::Languages::XML::Impl::Parser::buffer =~ $_ETAG_START);
          # print STDERR substr($MarpaX::Languages::XML::Impl::Parser::buffer, $pos, 2) . " =~ $_ETAG_START ? " . ($match ? "yes" : "no") ."\n";
          #
          # The parser will not know that we modified the input:
          # Restore original string and original position
          substr($MarpaX::Languages::XML::Impl::Parser::buffer, $length, $new_length - $length, '');
          pos($MarpaX::Languages::XML::Impl::Parser::buffer) = $pos;
        } else {
          $parser->eof(true);
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

