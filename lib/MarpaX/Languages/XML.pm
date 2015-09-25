use Moops;

# PODCLASSNAME

# ABSTRACT Marpa powered XML parser

class MarpaX::Languages::XML {
  use MarpaX::Languages::XML::Impl::Parser;
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
                 . join("\n",  map {"\t\t$_"} @{MarpaX::Languages::XML::Impl::PluginFactory->list('MarpaX::Languages::XML::Impl::WFC', ':all')})
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
                 . join("\n",  map {"\t\t$_"} @{MarpaX::Languages::XML::Impl::PluginFactory->list('MarpaX::Languages::XML::Impl::VC', ':all')})
                 . "\n\tTo completely disable you must pass the option value \":none\", that has lower priority than \":all\"."
                );
}

1;
