use strict;
use warnings;
use Sub::Future qw( future );
use Benchmark qw( cmpthese );

cmpthese( 1_000, {
    recurse => sub { fib_recur(20) },
    future  => sub { fib_future(20) },
});

sub fib_recur {
    my ($n) = @_;
    return $n if $n < 2;
    return fib_recur( $n - 1 ) + fib_recur( $n - 2 );
}

sub fib_future {
    my ($n) = @_;
    return $n if $n < 2;
    my $n1 = fib_future( $n - 1 );
    my $n2 = fib_future( $n - 2 );
    return $n1 + $n2;
}
