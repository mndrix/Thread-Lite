use strict;
use warnings;
use Sub::Future qw( future );
use Algorithms qw( is_prime );
use feature qw( say );

my $first = future { is_prime(38265121) };
my $second  = future { is_prime(38265121) };
say ( $first ? 'yes' : 'no' );
say ( $second ? 'yes' : 'no' );
