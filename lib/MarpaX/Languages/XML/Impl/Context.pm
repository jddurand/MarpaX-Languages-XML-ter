use Moops;

# PODCLASSNAME

# ABSTRACT: Context implementation

class MarpaX::Languages::XML::Impl::Context {
  use MarpaX::Languages::XML::Role::Context;
  use MarpaX::Languages::XML::Type::Grammar -all;
  use MarpaX::Languages::XML::Type::IO -all;
  use MarpaX::Languages::XML::Type::Encoding -all;
  use MarpaX::Languages::XML::Type::Recognizer -all;
  use MarpaX::Languages::XML::Type::LastLexemes -all;
  use MarpaX::Languages::XML::Type::NamespaceSupport -all;
  use Types::Common::Numeric -all;
  use Throwable::Factory
    IOException    => undef
    ;

  has io               => ( is => 'rw',   isa => IO,                required => 1, trigger => 1 );
  has grammar          => ( is => 'rw',   isa => Grammar,           required => 1, trigger => 1 );
  has encoding         => ( is => 'rwp',  isa => Encoding,          init_arg => undef );
  has recognizer       => ( is => 'rw',   isa => Recognizer,        predicate => 1 );
  has pos              => ( is => 'rw',   isa => PositiveOrZeroInt, default => 0 );
  has line             => ( is => 'rw',   isa => PositiveOrZeroInt, default => 1 );
  has column           => ( is => 'rw',   isa => PositiveOrZeroInt, default => 1 );
  has lastLexemes      => ( is => 'rw',   isa => LastLexemes,       default => sub { return {} } );
  has namespaceSupport => ( is => 'rwp',  isa => NamespaceSupport,  init_arg => undef );

  method _trigger_io(IO $io --> Undef) {
    #
    # Set binary mode
    #
    $io->binary;
    #
    # Position at the beginning
    #
    $io->pos(0);
    #
    # Read the first bytes. 1024 is far enough.
    #
    my $old_block_size = $io->block_size_value();
    $io->block_size(1024) if ($old_block_size != 1024);
    $io->read;
    IOException->throw('EOF when reading first bytes') if ($io->length <= 0);
    #
    # The stream is supposed to be opened with the correct encoding, if any
    # If there was no guess from the BOM, default will be UTF-8. Nevertheless we
    # do NOT set it immediately: if it UTF-8, the beginning of the XML file will
    # start with one byte chars only, which is compatible with binary mode.
    # And if it is not UTF-8, the first chars will tell us more.
    # If the encoding is setted to something else but what the BOM eventually says
    # this will be handled by a callback from the grammar.
    #
    # In theory we should have the localized buffer available. We "//" just in case
    #
    my $bytes = $MarpaX::Languages::XML::Impl::Parser::buffer // ${$io->buffer};
    #
    # An XML processor SHOULD work with case-insensitive encoding name. So we uc()
    # (note: per def an encoding name contains only Latin1 character, i.e. uc() is ok)
    #
    my $encoding = $self->_set_encoding(MarpaX::Languages::XML::Impl::Encoding->new(bytes => $bytes));
    #
    # Make sure we are positionned at the beginning of the buffer and at correct
    # source position. This is inefficient for everything that is not seekable.
    # And reset it appropriately to Encoding object
    #
    $io->pos($encoding->byteStart);
    $io->clear;
    $io->encoding($encoding->value);
    return;
  }

  method _trigger_grammar(Grammar $grammar --> Undef) {
    my %namespacesupport_options = (xmlns => $grammar->xmlns ? 1 : 0);
    $namespacesupport_options{xmlns_11} = ($grammar->xmlVersion eq '1.1' ? 1 : 0) if ($grammar->xmlns);
    $self->_set_namespaceSupport(XML::NamespaceSupport->new(\%namespacesupport_options));
    return;
  }

  with qw/MarpaX::Languages::XML::Role::Context/;
}

1;

