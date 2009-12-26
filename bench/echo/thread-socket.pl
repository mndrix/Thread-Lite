use strict;
use warnings;
use threads;
use IO::Socket;

unlink '/tmp/request.socket';
my $listen = IO::Socket::UNIX->new(
    Type   => SOCK_STREAM,
    Local  => '/tmp/request.socket',
    Listen => SOMAXCONN,
) or die $!;

my $child = async {
    my $channel = IO::Socket::UNIX->new(
        Peer => '/tmp/request.socket',
        Type => SOCK_STREAM,
    ) or die $!;
    $channel->autoflush(1);
    while (1) {
        my $value = <$channel>;
        return if $value eq "quit\n";
        print $channel "pong\n";
    }
};

my $channel = $listen->accept or die "Error accepting: $!\n";
$channel->autoflush(1);
for ( 1 .. 1_000_000 ) {
    print $channel "ping\n";
    my $response = <$channel>;
}
print $channel "quit\n";
$child->join;
