use Moops;

# PODCLASSNAME

# ABSTRACT: Parser role

role MarpaX::Languages::XML::Role::Parser {
  use MarpaX::Languages::XML::Role::WFC;
  use MarpaX::Languages::XML::Role::VC;

  # VERSION

  # AUTHORITY

  requires 'parse';

  with qw/MarpaX::Languages::XML::Role::WFC
          MarpaX::Languages::XML::Role::VC/;
}

1;
