package MarpaX::Languages::XML::Impl::ImmediateAction::Constant;

# VERSION

# AUTHORITY
#

use strictures 2;

sub IMMEDIATEACTION_NONE   () { 0 }
sub IMMEDIATEACTION_PAUSE  () { 1 }
sub IMMEDIATEACTION_STOP   () { 2 }
sub IMMEDIATEACTION_RESUME () { 3 }

use parent 'Exporter';

our @EXPORT = qw/IMMEDIATEACTION_NONE IMMEDIATEACTION_PAUSE IMMEDIATEACTION_STOP IMMEDIATEACTION_RESUME/;

1;

=pod

=begin Pod::Coverage

EAT.+

=end Pod::Coverage

=head1 NAME

MooX::Role::Pluggable::Constants - MooX::Role::Pluggable EAT values

=head1 SYNOPSIS

  ## Import EAT_NONE, EAT_CLIENT, EAT_PLUGIN, EAT_ALL :
  use MooX::Role::Pluggable::Constants;

=head1 DESCRIPTION

Exports constants used by L<MooX::Role::Pluggable/"_pluggable_process">:

  EAT_NONE   => 1
  EAT_CLIENT => 2
  EAT_PLUGIN => 3
  EAT_ALL    => 4

These are used by plugins to control the lifetime of a plugin-processed 
event. See L<MooX::Role::Pluggable/"_pluggable_process"> for details.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>, borrowing from 
L<Object::Pluggable::Constants>

=cut
