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
  use MarpaX::Languages::XML::Type::Grammar -all;
  use MarpaX::Languages::XML::Type::XmlVersion -all;
  use MarpaX::Languages::XML::Type::WFC -all;
  use MarpaX::Languages::XML::Type::VC -all;
  use MooX::HandlesVia;

  # VERSION

  # AUTHORITY

  has xmlVersion   => ( is => 'ro',  isa => XmlVersion,    required => 1 );
  has xmlns        => ( is => 'ro',  isa => Bool,          required => 1 );
  has vc           => ( is => 'ro',  isa => ArrayRef[Str], required => 1 );
  has wfc          => ( is => 'ro',  isa => ArrayRef[Str], required => 1 );

  has _dispatcher  => ( is => 'rwp', isa => Dispatcher,       lazy => 1, builder => 1 );
  has _wfcInstance => ( is => 'rwp', isa => WFC,              lazy => 1, builder => 1 );
  has _vcInstance  => ( is => 'rwp', isa => VC,               lazy => 1, builder => 1 );
  has _grammars    => ( is => 'rwp', isa => HashRef[Grammar], lazy => 1, builder => 1, handles_via => 'Hash', handles => { _get_grammar => 'get' } );

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

    my $io = MarpaX::Languages::XML::Impl::IO->new(source => $source);

    my $rc = 0;

    return $rc;
  }

  with 'MarpaX::Languages::XML::Role::Parser';
}

1;

