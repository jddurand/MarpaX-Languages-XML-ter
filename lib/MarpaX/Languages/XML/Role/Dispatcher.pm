use Moops;

# PODCLASSNAME

# ABSTRACT: Parser role

role MarpaX::Languages::XML::Role::Dispatcher {
  use MooX::Role::Pluggable;

  # VERSION

  # AUTHORITY

  requires 'notify';

  with qw/MooX::Role::Pluggable/;
}

1;
