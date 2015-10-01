use Moops;

# PODCLASSNAME

# ABSTRACT: SaxHandler implementation

class MarpaX::Languages::XML::Impl::SaxHandler {
  use MarpaX::Languages::XML::Role::SaxHandler;
  use MarpaX::Languages::XML::Type::SaxHandler -all;
  use MarpaX::Languages::XML::Type::SaxHandlerReturnCode -all;
  use MooX::HandlesVia;
  use POSIX qw/EXIT_SUCCESS EXIT_FAILURE/;

  has userHandler      => ( is => 'ro',   isa => SaxHandler,        default => sub { {} },
                            handles_via => 'Hash',
                            handles => {
                                        _get_userHandle => 'get',
                                        _exists_userHandle => 'exists'
                                       }
                          );

  method _proxyHandle(Str $handleName, @args --> SaxHandlerReturnCode) {
    if ($self->_exists_userHandle($handleName)) {
      my $handle = $self->_get_userHandle($handleName);
      return $self->$handle(@args);
    }
    return EXIT_SUCCESS;
  }

  method start_document( --> SaxHandlerReturnCode) {
    return $self->_proxyHandle('start_document', {});
  }

  method end_document( --> SaxHandlerReturnCode) {
    return $self->_proxyHandle('end_document', {});
  }


  with 'MarpaX::Languages::XML::Role::SaxHandler';
}

1;

