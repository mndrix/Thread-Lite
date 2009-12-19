use threads;
use strict;
use warnings;
use Sub::Future qw( future );
use Benchmark qw( cmpthese );

cmpthese( 1_000, {
    fork => sub {
        my $pid = fork;
        exit if not $pid;
        waitpid $pid, 0;
        return;
    },
    future  => sub {
        my $f = future { return 1 };
        $f->value;
        return;
    },
    threads => sub {
        my $t = async { return 1 };
        $t->join;
        return;
    },
});
