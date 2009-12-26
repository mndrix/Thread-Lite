use strict;
use warnings;
use Coro;
use Algorithms qw( is_prime );
use feature qw( say );

my $first = async { is_prime(38265121) };
my $second  = async { is_prime(38265121) };
say ( $first->join ? 'yes' : 'no' );
say ( $second->join ? 'yes' : 'no' );
