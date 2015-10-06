use Moops;

# PODCLASSNAME

# ABSTRACT: Reader role

# VERSION

# AUTHORITY

role MarpaX::Languages::XML::Role::Reader {
  use Types::Common::Numeric qw/PositiveOrZeroInt/;
  use MarpaX::Languages::XML::Type::BytesOrChars -all;

  requires 'read';
  #
  # We require to have a read method with exactly this
  # prototype, with the same semantics as Java's InputStream read() on bytes.
  # This would be:
  # around read(Bytes $bytes, PositiveOrZeroInt $off, PositiveOrZeroInt $len) {
  #   $self->${^NEXT}($bytes, $off, $len);
  # }
  # Except that I do NOT write it because $bytes should be modified
  # in place, i.e. in $_[0]. So the method should write e.g.:
  # {
  #   no warnings 'redefine';
  #   sub read {
  #     CORE::read($self->fh, @_);
  #   }
  # }

  around read(... --> Int) {
    BytesOrChars->assert_valid($_[0]), PositiveOrZeroInt->assert_valid($_[1]), PositiveOrZeroInt->assert_valid($_[2]), $self->${^NEXT}(@_)
  }

}

1;
