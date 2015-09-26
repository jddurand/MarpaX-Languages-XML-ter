use Moops;

# PODCLASSNAME

# ABSTRACT: Encoding role

role MarpaX::Languages::XML::Role::Encoding {

  # VERSION

  # AUTHORITY

  requires 'value';
  requires 'bytes';
  requires 'byteStart';
  requires 'merge_with_encodingFromXmlProlog';

}

1;
