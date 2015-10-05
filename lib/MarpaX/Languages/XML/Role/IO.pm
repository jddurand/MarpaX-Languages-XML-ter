use Moops;

# PODCLASSNAME

# ABSTRACT: I/O role

role MarpaX::Languages::XML::Role::IO {

  # VERSION

  # AUTHORITY

  requires 'reopen';
  requires 'block_size';
  requires 'block_size_value';
  requires 'binmode';
  requires 'read';
  requires 'write';
  requires 'is_string';
  requires 'string_ref';
  requires 'pos';
  requires 'tell';
  requires 'seek';
  requires 'clear';
  requires 'length';
  requires 'encoding';
  requires 'encodingName';
  requires 'buffer';
  requires 'eof';

}

1;
