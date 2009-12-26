use strict;
use warnings;
use IPC::Open2;

my ( $reader, $writer );
my $pid = open2 $reader, $writer, '-';
if ( $pid ) { # parent
    for ( 1 .. 1_000_000 ) {
        print $writer "ping\n";
        my $response = <$reader>;
    }
    print $writer "quit\n";
    waitpid $pid, 1;
}
else { # child
    while (<STDIN>) {
        exit if $_ eq "quit\n";
        print "pong\n";
    }
}
