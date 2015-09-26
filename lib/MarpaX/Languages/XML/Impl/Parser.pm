use Moops;

# PODCLASSNAME

# ABSTRACT: Parser implementation

class MarpaX::Languages::XML::Impl::Parser {
  use MarpaX::Languages::XML::Impl::Grammar;
  use MarpaX::Languages::XML::Impl::Dispatcher;
  use MarpaX::Languages::XML::Impl::IO;
  use MarpaX::Languages::XML::Impl::Encoding;
  use MarpaX::Languages::XML::Impl::WFC;
  use MarpaX::Languages::XML::Impl::VC;
  use MarpaX::Languages::XML::Role::Parser;
  use MarpaX::Languages::XML::Type::Dispatcher -all;
  use MarpaX::Languages::XML::Type::Encoding -all;
  use MarpaX::Languages::XML::Type::Grammar -all;
  use MarpaX::Languages::XML::Type::IO -all;
  use MarpaX::Languages::XML::Type::Parser -all;
  use MarpaX::Languages::XML::Type::XmlVersion -all;
  use MarpaX::Languages::XML::Type::WFC -all;
  use MarpaX::Languages::XML::Type::VC -all;
  use MooX::HandlesVia;
  use Throwable::Factory
    ParseException    => undef
    ;
  use Types::Common::Numeric -all;

  # VERSION

  # AUTHORITY

  has xmlVersion   => ( is => 'ro',  isa => XmlVersion,        required => 1 );
  has xmlns        => ( is => 'ro',  isa => Bool,              required => 1 );
  has vc           => ( is => 'ro',  isa => ArrayRef[Str],     required => 1 );
  has wfc          => ( is => 'ro',  isa => ArrayRef[Str],     required => 1 );
  has blockSize    => ( is => 'ro',  isa => PositiveOrZeroInt, default => 1024 * 1024 );
  has rc           => ( is => 'rwp', isa => Int,               default => 0 );

  has _dispatcher  => ( is => 'rw',  isa => Dispatcher,        lazy => 1, builder => 1 );
  has _wfcInstance => ( is => 'rw',  isa => WFC,               lazy => 1, builder => 1 );
  has _vcInstance  => ( is => 'rw',  isa => VC,                lazy => 1, builder => 1 );
  has _grammars    => ( is => 'rw',  isa => HashRef[Grammar],  lazy => 1, builder => 1, handles_via => 'Hash', handles => { _get_grammar => 'get' } );
  has _bufferRef   => ( is => 'rw',  isa => ScalarRef);

  method _build__dispatcher( --> Dispatcher )  {
    return MarpaX::Languages::XML::Impl::Dispatcher->new();
  }

  method _build__wfcInstance( --> WFC) {
    return MarpaX::Languages::XML::Impl::WFC->new(dispatcher => $self->_dispatcher, wfc => $self->wfc);
  }

  method _build__vcInstance( --> VC) {
    return MarpaX::Languages::XML::Impl::VC->new(dispatcher => $self->_dispatcher, vc => $self->wfc);
  }

  method _build__grammars( --> HashRef[Grammar]) {
    my %grammars = ();
    foreach (qw/document prolog element/) {
      $grammars{$_} = MarpaX::Languages::XML::Impl::Grammar->new(xmlVersion => $self->xmlVersion, xmlns => $self->xmlns, startSymbol => $_);
    }
    return \%grammars;
  }

  method parse(Str $source --> Int) {
    my $vcInstance      = $self->_vcInstance;
    my $wfcInstance     = $self->_wfcInstance;
    my $compiledGrammar = $self->_get_grammar('document')->compiledGrammar;
    my $io              = MarpaX::Languages::XML::Impl::IO->new(source => $source);
    my $rc              = 0;

    #
    # We want to handle buffer direcly with no COW: we pass buffer to all
    # routines
    #
    my $buffer = '';
    $io->buffer($self->_bufferRef(\$buffer));

    return $self->_parse_prolog($io)->_parse_element($io)->rc;
  }

  method _find_encoding(IO $io --> Encoding) {
    #
    # Set binary mode
    #
    $io->binary;
    #
    # Read the first bytes. 1024 is far enough.
    #
    my $old_block_size = $io->block_size_value();
    $io->block_size(1024) if ($old_block_size != 1024);
    $io->read;
    ParseException->throw('EOF when reading first bytes') if ($io->length <= 0);
    my $buffer = ${$self->_bufferRef};
    my $encoding = MarpaX::Languages::XML::Impl::Encoding->new(bytes => ${$self->_bufferRef});
    $io->encoding($encoding->value);
    #
    # The stream is supposed to be opened with the correct encoding, if any
    # If there was no guess from the BOM, default will be UTF-8. Nevertheless we
    # do NOT set it immediately: if it UTF-8, the beginning of the XML file will
    # start with one byte chars only, which is compatible with binary mode.
    # And if it is not UTF-8, the first chars will tell us more.
    # If the encoding is setted to something else but what the BOM eventually says
    # this will be handled by a callback from the grammar.
    #
    # An XML processor SHOULD work with case-insensitive encoding name. So we uc()
    # (note: per def an encoding name contains only Latin1 character, i.e. uc() is ok)
    #
    return $encoding;
}
  method _parse_prolog(IO $io --> Parser) {

    my $encoding = $self->_find_encoding($io);
    #
    # Make sure we are positionned at the beginning of the buffer and at correct
    # source position. This is inefficient for everything that is not seekable.
    #
    $io->clear;
    $io->pos($encoding->byteStart);
    #
    # Initial block size and read
    #
    $io->block_size($self->blockSize);
    $io->read;

    return $self;
  }

  method _parse_element(IO $io --> Parser) {
    return $self;
  }

  with 'MarpaX::Languages::XML::Role::Parser';
}

1;

