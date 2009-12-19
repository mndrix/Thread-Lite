use strict;
use warnings;
use Data::Dump::Streamer qw( Dump );
use Storable qw( freeze thaw );
use Benchmark qw( cmpthese );

$Storable::Deparse = $Storable::Eval = 1;

cmpthese( 10_000, {
    dds       => sub {
        my $frozen = Dump(\&foo);
        eval $frozen;
    },
    storable  => sub {
        my $frozen = freeze(\&foo);
        thaw($frozen);
    },
});

sub foo {
    print "This is a simple coderef\n";
}
