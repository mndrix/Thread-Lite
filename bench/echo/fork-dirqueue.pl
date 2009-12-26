use strict;
use warnings;
use IPC::DirQueue;

my $requests = IPC::DirQueue->new({ dir => '/tmp/requests' });
my $responses = IPC::DirQueue->new({ dir => '/tmp/responses' });

my $pid = fork;
if ( $pid ) { # parent
    for ( 1 .. 10 ) {
        $requests->enqueue_string("ping\n");
        $responses->wait_for_queued_job
    }
    $requests->enqueue_string("quit\n");
    waitpid $pid, 1;
}
else { # child
    while ( my $request = $requests->wait_for_queued_job ) {
        my $value = $request->get_data;
        exit if $value eq "quit\n";
        $responses->enqueue_string("pong\n");
    }
}
