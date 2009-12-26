use strict;
use warnings;
use threads;
use Thread::Queue;

my $request = Thread::Queue->new;
my $response = Thread::Queue->new;
my $child = async {
    while (1) {
        my $value = $request->dequeue;
        return if $value eq "quit\n";
        $response->enqueue("pong\n" );
    }
};

for ( 1 .. 100_000 ) {
    my $id = $request->enqueue("ping\n");
    $response->dequeue;
}
$request->enqueue("quit\n");
$child->join;
