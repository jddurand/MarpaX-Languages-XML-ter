use Moops;

# PODCLASSNAME

# ABSTRACT: End-of-line plugin implementation

class MarpaX::Languages::XML::Impl::Plugin::IO::EOL {
  use MarpaX::Languages::XML::Impl::Plugin;
  use MarpaX::Languages::XML::Type::PluggableConstant -all;
  use MarpaX::Languages::XML::Type::Context -all;
  use MarpaX::Languages::XML::Type::Dispatcher -all;
  use MarpaX::Languages::XML::Type::Parser -all;
  use MooX::Role::Logger;
  use MooX::Role::Pluggable::Constants;
  use Throwable::Factory
    EOLException => undef;

  extends qw/MarpaX::Languages::XML::Impl::Plugin/;

  has '+subscriptions' => (default => sub { return
                                              {
                                               PROCESS => [ 'EOL' ]
                                              };
                                          }
                          );

  my $_impl;

  method BUILD {
    $_impl = ($self->xmlVersion eq '1.0') ? \&_impl10 : \&_impl11;
  };

  sub _impl11 {
    my ($self, $dispatcher, $parser, $context, undef) = @_;
    #
    # Buffer is in $_[4]
    #
    if (substr($_[4], -1, 1) eq "\x{D}") {
      $self->_logger->tracef('Last character in buffer is \\x{D} and requires another read');
      return EAT_PLUGIN;
    }

    $_[4] =~ s/\x{D}\x{A}/\x{A}/g;
    $_[4] =~ s/\x{D}\x{85}/\x{A}/g;
    $_[4] =~ s/\x{85}/\x{A}/g;
    $_[4] =~ s/\x{2028}/\x{A}/g;
    $_[4] =~ s/\x{D}/\x{A}/g;

    return EAT_CLIENT;
  }

  sub _impl10 {
    my ($self, $dispatcher, $parser, $context, undef) = @_;
    #
    # Buffer is in $_[4]
    #
    if (substr($_[4], -1, 1) eq "\x{D}") {
      $self->_logger->tracef('Last character in buffer is \\x{D} and requires another read');
      return EAT_PLUGIN;
    }

    $_[4] =~ s/\x{D}\x{A}/\x{A}/g;
    $_[4] =~ s/\x{D}/\x{A}/g;

    return EAT_CLIENT;
  }

  sub P_EOL {
    #
    # Faster like this
    #
    goto &$_impl;
  }

  with 'MooX::Role::Logger';
}

1;

