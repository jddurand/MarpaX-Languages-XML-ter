package MarpaX::Languages::XML::Impl::ImmediateAction::Constant;

# VERSION

# AUTHORITY

sub  IMMEDIATEACTION_NONE                         () { 0x00 }
sub  IMMEDIATEACTION_RETURN                       () { 0x01 }
sub  IMMEDIATEACTION_POP_CONTEXT                  () { 0x02 }
sub  IMMEDIATEACTION_MARK_EVENTS_DONE             () { 0x04 }
sub  IMMEDIATEACTION_READONECHAR                  () { 0x08 }
sub  IMMEDIATEACTION_REDUCE                       () { 0x10 }

use parent 'Exporter';

our @EXPORT = qw/IMMEDIATEACTION_NONE
                 IMMEDIATEACTION_RETURN
                 IMMEDIATEACTION_POP_CONTEXT
                 IMMEDIATEACTION_MARK_EVENTS_DONE
                 IMMEDIATEACTION_READONECHAR
                 IMMEDIATEACTION_REDUCE/;

1;
