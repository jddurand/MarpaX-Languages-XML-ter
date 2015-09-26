use Moops;

# PODCLASSNAME

# ABSTRACT: Encoding role

role MarpaX::Languages::XML::Role::Encoding {

  # VERSION

  # AUTHORITY

  requires 'bom';
  requires 'bom_size';

  requires 'guess';
  requires 'analyse_bom';

}

1;
