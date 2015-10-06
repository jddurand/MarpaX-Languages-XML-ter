package MarpaX::Languages::XML::Type::StreamChars;
use Type::Library
  -base,
  -declare => qw/StreamChars/;
use Type::Utils -all;
use Types::Standard -types;
use Types::Encodings -types;       # To get Bytes
use Encode;

# VERSION

# AUTHORITY

# Note: the same thing as Types::Encodings::Chars except this is in streaming mode
#       Types::Standard is defining the _croak() routine

our $CHECK = $ENV{STREAMCHARS_DEBUG} ? Encode::FB_WARN : Encode::FB_QUIET;

declare StreamChars,
  as Chars;

declare_coercion Decode => to_type StreamChars, {
                                                 coercion_generator => sub {
                                                   my ($self, $target, $encoding) = @_;
                                                   require Encode;
                                                   Encode::find_encoding($encoding)
                                                       or _croak("Parameter \"$encoding\" for Decode[`a] is not an encoding supported by this version of Perl");
                                                   require B;
                                                   $encoding = B::perlstring($encoding);
                                                   return (Bytes, qq{state \$buffer; \$buffer .= \$_, Encode::decode($encoding, \$buffer, $CHECK)});
                                                 },
                                                };

1;
