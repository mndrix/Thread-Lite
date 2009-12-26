use threads;
use strict;
use warnings;
use Thread::Lite;
use Benchmark qw( cmpthese );

cmpthese( 1_000, {
    fork => sub {
        my $pid = fork;
        exit if not $pid;
        waitpid $pid, 0;
        return;
    },
    thread_lite  => sub {
        my $f = Thread::Lite::async { return 1 };
        $f->join;
        return;
    },
    threads => sub {
        my $t = async { return 1 };
        $t->join;
        return;
    },
});
