package MarpaX::Languages::XML::Type::ImmediateAction;
use Type::Library
  -base,
  -declare => qw/ImmediateAction/;
use Type::Utils -all;
use Types::Standard -types;
use MarpaX::Languages::XML::Impl::ImmediateAction::Constant;

# VERSION

# AUTHORITY

declare ImmediateAction,
  as Enum[IMMEDIATEACTION_NONE, IMMEDIATEACTION_PAUSE, IMMEDIATEACTION_STOP, IMMEDIATEACTION_RESUME];

1;
