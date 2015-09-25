use Moops;

# PODCLASSNAME

# ABSTRACT: Well-Formed constraint implementation

class MarpaX::Languages::XML::Impl::WFC {  # dirty becaue of Class::Factory::Util that I could have rewriten
  use MarpaX::Languages::XML::Impl::PluginsRegister;
  use MarpaX::Languages::XML::Role::WFC;
  use MarpaX::Languages::XML::Type::Dispatcher -all;
  use MooX::HandlesVia;

  #
  # Singleton
  #
  my $pluginsRegister = MarpaX::Languages::XML::Impl::PluginsRegister->instance;

  has dispatcher => (
                     is => 'ro',
                     isa => Dispatcher,
                     required => 1
                    );

  has wfc => (
              is => 'ro',
              isa => ArrayRef[Str],
              handles_via => 'Array',
              handles => {
                          'elements_wfc' => 'elements'
                         },
              required => 1,
              trigger => 1,
             );

  method _trigger_wfc(ArrayRef[Str] $wfc  --> Undef) {
    return $pluginsRegister->pluginsRegister(__PACKAGE__, $self->dispatcher, $self->elements_wfc);
  }

  with 'MarpaX::Languages::XML::Role::WFC';
}

1;

