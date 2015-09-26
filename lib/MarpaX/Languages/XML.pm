use Moops;

# PODCLASSNAME

# ABSTRACT Marpa powered XML parser

class MarpaX::Languages::XML {
  use MarpaX::Languages::XML::Impl::Parser;
  use MarpaX::Languages::XML::Type::Loglevel -all;
  use MarpaX::Languages::XML::Type::XmlVersion -all;
  use MooX::Options;

  # ---------------------------------------------------------------------------
  has parser => (
                 is => 'rwp',
                 isa => InstanceOf['MarpaX::Languages::XML::Impl::Parser'],
                 lazy => 1,
                 builder => 1
                );
  method _build_parser (--> InstanceOf['MarpaX::Languages::XML::Impl::Parser']) {
    return MarpaX::Languages::XML::Impl::Parser->new(xmlVersion => $self->xml, xmlns => $self->xmlns, wfc => $self->wfc, vc => $self->vc);
  }
  # ---------------------------------------------------------------------------
  option wfc => (
                 is => 'ro',
                 isa => ArrayRef[Str],
                 default => sub { [ ':all' ] },
                 #
                 # Options
                 #
                 format => 's@',
                 autosplit => ',',
                 short => 'w',
                 doc =>
                 "Well-Formed constraints. Repeatable option. Default is \":all\". Supported values are:\n"
                 . join(",\n",  map {"\t\t$_"} MarpaX::Languages::XML::Impl::WFC->listAllPlugins('MarpaX::Languages::XML::Impl::WFC'), ':all', ':none') . "."
                 . "\n\tList is taken in order: \":all\" to push all plugins, \":none\" to remove everything, \"no-X\" to remove plugin \"X\"."
                );
  # ---------------------------------------------------------------------------
  option vc => (
                is => 'ro',
                isa => ArrayRef[Str],
                default => sub { [ ':all' ] },
                #
                # Options
                #
                format => 's@',
                autosplit => ',',
                short => 'v',
                doc =>
                 "Validation constraints. Repeatable option. Default is \":all\". Supported values are:\n"
                 . join(",\n",  map {"\t\t$_"} MarpaX::Languages::XML::Impl::VC->listAllPlugins('MarpaX::Languages::XML::Impl::VC'), ':all', ':none') . "."
                 . "\n\tList is taken in order: \":all\" to push all plugins, \":none\" to remove everything, \"no-X\" to remove plugin \"X\"."
                );
  # ---------------------------------------------------------------------------
  option loglevel => (
                      is => 'rwp',
                      isa => Loglevel,
                      default => 'WARN',
                      #
                      # Options
                      #
                      format => 's',
                      short => 'l',
                      doc => q{Set log level. Default value: "WARN". Supported values: "DEBUG", "INFO", "WARN", "ERROR", "FATAL", "TRACE".},
                     );
  # ---------------------------------------------------------------------------
  option xml => (
                 is => 'ro',
                 isa => XmlVersion,
                 default => '1.0',
                 #
                 # Options
                 #
                 format => 's',
                 short => 'x',
                 doc => q{Force XML Version. Default is "1.0". Supported values: "1.0" and "1.1".}
                );
  # ---------------------------------------------------------------------------
  option xmlns => (
                   is => 'ro',
                   isa => Bool,
                   default => true,
                   #
                   # Options
                   #
                   negativable => 1,
                   doc => q{Namespace support. Default is a true value. Say --no-xmlns to disable.}
                  );
}

1;
