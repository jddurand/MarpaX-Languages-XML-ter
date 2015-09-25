use Moops;

# PODCLASSNAME

# ABSTRACT Marpa powered XML parser

class MarpaX::Languages::XML {
  use MarpaX::Languages::XML::Impl::Parser;
  use MarpaX::Languages::XML::Role::PluginFactory;
  use MarpaX::Languages::XML::Type::Loglevel -all;
  use MooX::Options;

  # ---------------------------------------------------------------------------
  has parser => (
                 is => 'rwp',
                 isa => InstanceOf['MarpaX::Languages::XML::Impl::Parser'],
                 lazy => 1,
                 builder => 1
                );
  method _build_parser (--> InstanceOf['MarpaX::Languages::XML::Impl::Parser']) {
    return MarpaX::Languages::XML::Impl::Parser->new(wfc => $self->wfc, vc => $self->vc);
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
                 "Well-Formed constraints. Repeatable option. Default is \":all\". Other supported values are:\n"
                 . join("\n",  map {"\t\t$_"} MarpaX::Languages::XML::Impl::WFC->listAllPlugins('MarpaX::Languages::XML::Impl::WFC'), ':all', ':none')
                 . "\n\tTo completely disable you must pass the option value \":none\", that has lower priority than \":all\"."
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
                 "Validation constraints. Repeatable option. Default is \":all\". Other supported values are:\n"
                 . join("\n",  map {"\t\t$_"} MarpaX::Languages::XML::Impl::VC->listAllPlugins('MarpaX::Languages::XML::Impl::VC'), ':all', ':none')
                 . "\n\tTo completely disable you must pass the option value \":none\", that has lower priority than \":all\"."
                );
  # ---------------------------------------------------------------------------
  has loglevel => (
                   is => 'rw',
                   isa => Loglevel,
                   default => 'WARN',
                  );

  # ---------------------------------------------------------------------------
  # The followings are not used and exist just because of MooX::Options and the
  # marpaxml executable.
  # ---------------------------------------------------------------------------

  option debug => (
                   is => 'rwp',
                   isa => Bool,
                   trigger => 1,
                   #
                   # Options
                   #
                   doc => q{set the log level to DEBUG.}
                  );
  method _trigger_debug(Bool $debug) {
    $self->loglevel('DEBUG') if ($debug);
  }
  # ---------------------------------------------------------------------------
  option info => (
                   is => 'rwp',
                   isa => Bool,
                   trigger => 1,
                   #
                   # Options
                   #
                   doc => q{set the log level to INFO.}
                  );
  method _trigger_info(Bool $info) {
    $self->loglevel('INFO') if ($info);
  }
  # ---------------------------------------------------------------------------
  option warn => (
                   is => 'rwp',
                   isa => Bool,
                   trigger => 1,
                   #
                   # Options
                   #
                   doc => q{set the log level to WARN.}
                  );
  method _trigger_warn(Bool $warn) {
    $self->loglevel('WARN') if ($warn);
  }
  # ---------------------------------------------------------------------------
  option error => (
                   is => 'rwp',
                   isa => Bool,
                   trigger => 1,
                   #
                   # Options
                   #
                   doc => q{set the log level to ERROR.}
                  );
  method _trigger_error(Bool $error) {
    $self->loglevel('ERROR') if ($error);
  }
  # ---------------------------------------------------------------------------
  option fatal => (
                   is => 'rwp',
                   isa => Bool,
                   trigger => 1,
                   #
                   # Options
                   #
                   doc => q{set the log level to FATAL.}
                  );
  method _trigger_fatal(Bool $fatal) {
    $self->loglevel('FATAL') if ($fatal);
  }
  # ---------------------------------------------------------------------------
  option trace => (
                   is => 'rwp',
                   isa => Bool,
                   trigger => 1,
                   #
                   # Options
                   #
                   doc => q{set the log level to TRACE.}
                  );
  method _trigger_trace(Bool $trace) {
    $self->loglevel('TRACE') if ($trace);
  }

  with 'MarpaX::Languages::XML::Role::PluginFactory';
}

1;
