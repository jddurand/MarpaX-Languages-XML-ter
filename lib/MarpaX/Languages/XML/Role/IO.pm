use Moops;

# PODCLASSNAME

# ABSTRACT: I/O role

role MarpaX::Languages::XML::Role::IO {

  # VERSION

  # AUTHORITY

  requires 'source';
  requires 'block_size';
  requires 'block_size_value';
  requires 'binary';
  requires 'read';
  requires 'pos';
  requires 'tell';
  requires 'seek';
  requires 'clear';
  requires 'length';
  requires 'encoding';
  requires 'buffer';
  requires 'eof';

}

1;
