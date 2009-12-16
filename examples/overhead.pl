use threads;
use strict;
use warnings;
use Sub::Future qw( future );
use Benchmark qw( cmpthese );

cmpthese( 100, {
    fork => sub {
        my $pid = fork;
        exit if not $pid;
        waitpid $pid, 0;
        return;
    },
    future  => sub {
        my $f = future { return };
        $f->value;
    },
    threads => sub {
        my $t = async { return };
        $t->join;
    },
});
