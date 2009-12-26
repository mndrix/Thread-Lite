use strict;
use warnings;
use Thread::Lite qw( async );
use Benchmark qw( cmpthese );

cmpthese( 1_000, {
    recurse => sub { fib_recur(20) },
    thread  => sub { fib_thread(20) },
});

sub fib_recur {
    my ($n) = @_;
    return $n if $n < 2;
    return fib_recur( $n - 1 ) + fib_recur( $n - 2 );
}

sub fib_thread {
    my ($n) = @_;
    return $n if $n < 2;
    my $n1 = async { fib_thread( $n - 1 ) };
    my $n2 = async { fib_thread( $n - 2 ) };
    return $n1->join + $n2->join;
}
