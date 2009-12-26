package Thread::Lite::Worker;
use strict;
use warnings;

use Data::Dump::Streamer;
use IPC::Open2 qw();
use IO::Handle;

sub new {
    my $class = shift;

    my ( $writer, $reader );
    my $pid = IPC::Open2::open2( $reader, $writer, '-' );
    if ( $pid ) { # in the parent
        $writer->autoflush(1);
        return bless {
            pid         => $pid,
            reader      => $reader,
            writer      => $writer,
        }, $class;
    }

    # in the worker itself (child)
    STDOUT->autoflush(1);
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
    my $writer = $self->writer;
    print $writer sprintf("\n# targeting worker %d\n$frozen_job\0", $self->pid);
    return;
}

# Methods run in the worker process

# listens for new jobs to arrive and works on them
sub listen {
    my ($self) = @_;
    while ( my $frozen_job = do { local $/="\0"; <STDIN> } ) {
        do { local $/="\0"; chomp($frozen_job) };
        $self->warn("got frozen job: $frozen_job");
        my $job;
        eval $frozen_job;
        my $code = delete $job->{code};
        $job->{value} = $code->();
        $self->warn( "sending job: $frozen_job");
        $frozen_job = Dump($job)->Names('job')->Out;
        $self->warn( "answer: $frozen_job" );
        print "# answer back to scheduler\n$frozen_job\0";
    }
}

sub warn {
    my ($self, $msg) = @_;
    return if not $ENV{DEBUG};
    use Log::StdLog {
        level => 'trace',
        file  => '/Users/michael/src/Thread-Lite/errors.log'
    };
    print {*STDLOG} warn => "Worker: $msg\n";
}

1;
