package MarpaX::Languages::XML::Type::IO;
use Type::Library
  -base,
  -declare => qw/IO/;
use Type::Utils -all;
use Types::Standard -types;
use Scalar::Util qw/blessed/;

# VERSION

# AUTHORITY

our @METHODS = qw/seek tell read binmode/;

declare IO,
  as Object,
  where     {                   ! grep {! $_->can($_)   } @METHODS },
  inline_as { "Scalar::Util::blessed($_[1]) && ! grep {! $_[1]->can(\$_)} qw/@METHODS/"}
  ;

1;
