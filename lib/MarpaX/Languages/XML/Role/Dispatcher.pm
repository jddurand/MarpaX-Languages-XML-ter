use Moops;

# PODCLASSNAME

# ABSTRACT: Parser role

role MarpaX::Languages::XML::Role::Dispatcher {
  use MarpaX::Languages::XML::Role::Pluggable;

  # VERSION

  # AUTHORITY

  requires 'notify';

  with qw/MarpaX::Languages::XML::Role::Pluggable/;
}

1;
