use Moops;

# PODCLASSNAME

# ABSTRACT Marpa powered XML parser

class MarpaX::Languages::XML {
  use MarpaX::Languages::XML::Impl::Parser;
  use MarpaX::Languages::XML::Impl::PluginFactory;
  use MarpaX::Languages::XML::Type::Loglevel -all;
  use MarpaX::Languages::XML::Type::XmlVersion -all;
  use MooX::Options protect_argv => 0;;
  use Types::Common::Numeric -all;

  # ---------------------------------------------------------------------------
  has parser => (
                 is => 'rwp',
                 isa => InstanceOf['MarpaX::Languages::XML::Impl::Parser'],
                 lazy => 1,
                 builder => 1
                );
  method _build_parser (--> InstanceOf['MarpaX::Languages::XML::Impl::Parser']) {
    return MarpaX::Languages::XML::Impl::Parser->new(xmlVersion => $self->xml,
                                                     xmlns      => $self->xmlns,
                                                     wfc        => $self->wfc,
                                                     vc         => $self->vc,
                                                     blockSize  => $self->blocksize,
                                                     unicode_newline => $self->unicode_newline);
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
                 . join(",\n",  map {"\t\t$_"} MarpaX::Languages::XML::Impl::PluginFactory->listAllPlugins('MarpaX::Languages::XML::Impl::WFC'), ':all', ':none') . "."
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
                 . join(",\n",  map {"\t\t$_"} MarpaX::Languages::XML::Impl::PluginFactory->listAllPlugins('MarpaX::Languages::XML::Impl::VC'), ':all', ':none') . "."
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
                 doc => q{XML Version hint. Default is "1.0". Supported values: "1.0" and "1.1". If the parser detect another version it will automatically switch.}
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
  # ---------------------------------------------------------------------------
  option blocksize => (
                       is => 'ro',
                       isa => PositiveInt,
                       default => 1024 * 1024,
                       #
                       # Options
                       #
                       format => 'i',
                       short => 'b',
                       doc => q{I/O block length. At the very beginning this really mean bytes, and when encoding is determined this mean number of characters. Default value is 1M. Must be a positive value.}
                  );
  # ---------------------------------------------------------------------------
  option unicode_newline => (
                             is => 'ro',
                             isa => Bool,
                             default => false,
                             #
                             # Options
                             #
                             short => 'u',
                             doc => q{Unicode newline. Has an impact on counting line and column numbers. Default to a false value, which mean that what wour current OS think is a newline will be used.}
                            );
}

1;
