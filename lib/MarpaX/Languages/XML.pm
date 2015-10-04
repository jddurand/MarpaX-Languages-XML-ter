use Moops;

# PODCLASSNAME

# ABSTRACT Marpa powered XML parser

class MarpaX::Languages::XML {
  use Class::Load qw/load_class/;
  use MarpaX::Languages::XML::Impl::Parser;
  use MarpaX::Languages::XML::Impl::PluginFactory;
  use MarpaX::Languages::XML::Type::Loglevel -all;
  use MarpaX::Languages::XML::Type::SaxHandler -all;
  use MarpaX::Languages::XML::Type::SaxHandlerReturnCode -all;
  use MarpaX::Languages::XML::Type::XmlVersion -all;
  use MarpaX::Languages::XML::Type::StartSymbol -all;
  use MooX::HandlesVia;
  use MooX::Options protect_argv => 0;
  use MooX::Role::Logger;
  use POSIX qw/EXIT_SUCCESS EXIT_FAILURE/;
  use Types::Common::Numeric -all;

  method _pluginsToDoc(ClassName $class: Str $baseClass, Str $pluginName) {
    my $pkg = "$baseClass::$pluginName";
    my $doc = '';
    try {
      load_class($pkg);
      $doc = ' (' . $pkg->new->doc . ')';
    };
    return $doc;
  };

  # ---------------------------------------------------------------------------
  has parser => (
                 is => 'rwp',
                 isa => InstanceOf['MarpaX::Languages::XML::Impl::Parser'],
                 lazy => 1,
                 builder => 1
                );
  method _build_parser (--> InstanceOf['MarpaX::Languages::XML::Impl::Parser']) {
    return MarpaX::Languages::XML::Impl::Parser->new(xmlVersion      => $self->xmlversion,
                                                     xmlns           => $self->xmlns,
                                                     wfc             => $self->wfc,
                                                     vc              => $self->vc,
                                                     blockSize       => $self->blocksize,
                                                     unicode_newline => $self->unicode_newline,
                                                     saxHandler      => $self->saxHandler);
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
                 "Well-Formed constraints. Use comma \",\" to separate multiple values. Default is \":all\". Supported values are:\n"
                 . join(",\n", map
                        {"\t\t$_" . __PACKAGE__->_pluginsToDoc('MarpaX::Languages::XML::Impl::Plugin::WFC', $_)}
                        MarpaX::Languages::XML::Impl::PluginFactory->listAllPlugins('MarpaX::Languages::XML::Impl::Plugin::WFC'), ':all', ':none') . "."
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
                 "Validation constraints. Use comma \",\" to separate multiple values. Default is \":all\". Supported values are:\n"
                 . join(",\n",  map
                        {"\t\t$_" . __PACKAGE__->_pluginsToDoc('MarpaX::Languages::XML::Impl::Plugin::VC', $_)}
                        MarpaX::Languages::XML::Impl::PluginFactory->listAllPlugins('MarpaX::Languages::XML::Impl::Plugin::VC'), ':all', ':none') . "."
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
  option startsymbol => (
                         is => 'ro',
                         isa => StartSymbol,
                         default => 'document',
                         #
                         # Options
                         #
                         format => 's',
                         doc => q{Start symbol. Default is "document". Supported values: "document", "extParsedEnt", "extSubset", "Char".}
                        );
  # ---------------------------------------------------------------------------
  option xmlversion => (
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
  # ---------------------------------------------------------------------------
  option sax => (
                 is => 'ro',
                 isa => ArrayRef[Str],
                 default => sub { [] },
                 handles_via => 'Array',
                 handles => {
                             _elements_sax => 'elements'
                            },
                 #
                 # Options
                 #
                 format => 's@',
                 autosplit => ',',
                 short => 's',
                 doc => q{Assign a default SAX Handler that will just log to the INFO loglevel their argument(s). Use comma \",\" to separate multiple values. Default is an empty list. For example: --sax start_document,start_element,end_element,end_document. If you give ":all", all possible handlers will be activated.}
                );

  method _start_document(--> SaxHandlerReturnCode) { $self->_logger->infof('%s%s', 'start_document', \@_); return EXIT_SUCCESS; }
  method _start_element (--> SaxHandlerReturnCode) { $self->_logger->infof('%s%s', 'start_element',  \@_); return EXIT_SUCCESS; }
  method _end_element   (--> SaxHandlerReturnCode) { $self->_logger->infof('%s%s', 'end_element',    \@_); return EXIT_SUCCESS; }
  method _end_document  (--> SaxHandlerReturnCode) { $self->_logger->infof('%s%s', 'end_document',   \@_); return EXIT_SUCCESS; }

  has saxHandler => ( is => 'ro',
                      isa => SaxHandler,
                      builder => 1
                    );

  method _build_saxHandler( --> SaxHandler) {
    my %saxHandler = ();
    my @elements = $self->_elements_sax;
    if (grep {$_ eq ':all'} @elements) {
      @elements =  qw/start_document
                      start_element
                      end_element
                      end_document/;
    }
    foreach (@elements) {
         if ($_ eq 'start_document') { $saxHandler{$_} = \&_start_document; }
      elsif ($_ eq 'start_element')  { $saxHandler{$_} = \&_start_element;  }
      elsif ($_ eq 'end_element')    { $saxHandler{$_} = \&_end_element;    }
      elsif ($_ eq 'end_document')   { $saxHandler{$_} = \&_end_document;   }
      else  { $self->_logger->warnf('Unsupported SAX event %s', $_); }
    }
    return \%saxHandler;
  }

  with 'MooX::Role::Logger';
}

1;
