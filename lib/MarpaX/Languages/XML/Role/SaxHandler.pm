use Moops;

# PODCLASSNAME

# ABSTRACT: SaxHandler role

role MarpaX::Languages::XML::Role::SaxHandler {

  # VERSION

  # AUTHORITY

  requires 'userHandler';

  requires 'start_document';
  requires 'end_document';
}

1;
