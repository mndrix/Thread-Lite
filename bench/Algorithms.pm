package Algorithms;
use strict;
use warnings;
use base 'Exporter';

BEGIN { our @EXPORT_OK = qw( is_prime ) };

sub is_prime {
    my ($n) = @_;

    my $p = 2;
    while ( $p <= $n ) {
        return if $n % $p == 0;
        $p++;
    }

    return 1;
}

1;
