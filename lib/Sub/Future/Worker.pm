package Sub::Future::Worker;
use strict;
use warnings;

use Data::Dump::Streamer;
use IPC::Open2 qw();

sub new {
    my $class = shift;

    my ( $writer, $reader );
    my $pid = IPC::Open2::open2( $reader, $writer, '-' );

    # in the parent
    return bless {
        pid         => $pid,
        reader      => $reader,
        writer      => $writer,
    }, $class if $pid;

    # in the worker itself (child)
    my $self = bless { }, $class;
    local $SIG{HUP} = sub { exit };
    $self->listen;
}

# accessors
sub pid    { shift->{pid}    }
sub reader { shift->{reader} }
sub writer { shift->{writer} }

# Methods called from the scheduler process

# gives the worker process something to do
sub assign_job {
    my ( $self, $frozen_job ) = @_;
    warn "Scheduler assigning job: $frozen_job\n" if $ENV{DEBUG};
    my $writer = $self->writer;
    local $| = 1;
    print $writer $frozen_job;
    return;
}

# Methods run in the worker process

# listens for new jobs to arrive and works on them
sub listen {
    my ($self) = @_;
    while ( my $frozen_job = do { local $/="\0"; <STDIN> } ) {
        warn "Worker got frozen job: $frozen_job\n" if $ENV{DEBUG};
        my $job;
        eval $frozen_job;
        my $code = delete $job->{code};
        $job->{value} = $code->();
        use Data::Dumper;
        warn "Worker sending job: ", Dumper($job), "\n" if $ENV{DEBUG};
        local $| = 1;
        Dump($job)->To( \*STDOUT )->Names('job')->Out;
        print "\0";
        warn "Worker sent the finished job to scheduler\n" if $ENV{DEBUG};
    }
}

1;
