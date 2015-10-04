use Moops;

# PODCLASSNAME

# ABSTRACT: I/O role

role MarpaX::Languages::XML::Role::IO {

  # VERSION

  # AUTHORITY

  requires 'open';
  requires 'reopen';
  requires 'close';
  requires 'block_size';
  requires 'block_size_value';
  requires 'binmode';
  requires 'read';
  requires 'write';
  requires 'append';
  requires 'name';
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
