package Thread::Lite::Scheduler;
use strict;
use warnings;

use AnyEvent;
use AnyEvent::Handle;
use IPC::Open2 qw();
use Data::Dump::Streamer;
use Thread::Lite::Worker;
use IO::Select;
use IO::Handle;
use Sys::CPU qw();

sub new {
    my $class = shift;

    my ( $writer, $reader );
    my $pid = IPC::Open2::open2( $reader, $writer, '-' );
    $writer->autoflush(1);

    # in the parent
    return bless {
        pid         => $pid,
        reader      => $reader,
        writer      => $writer,
        next_job_id => 1,
    }, $class if $pid;

    # in the scheduler itself (child)
    my $self = bless {
        allowed => Sys::CPU::cpu_count(),
        workers => {},
        watchers => [],
    }, $class;
    $self->listen;
}

sub workers {
    my ($self) = @_;
    return map { $_->{worker} } values %{ $self->{workers} };
}

# Scheduler client methods (run in the parent process)

# schedules a new job for running and returns a Thread::Lite object
sub start {
    my ( $self, $code ) = @_;

    # send the job to the scheduler server process
    my $job = {
        id   => $self->{next_job_id}++,
        code => $code,
    };
    local $| = 1;
    my $frozen_job = Dump($job)->Names('job')->Out;
    my $writer = $self->{writer};
    $self->warn("app sending job $job->{id}");
    print $writer "# app to scheduler\n$frozen_job\0";
    $self->warn("app sent job $job->{id}");

    return bless { id => $job->{id} }, 'Thread::Lite';
}

# wait for a specific future's answer to be available
sub wait_on {
    my ( $self, $future ) = @_;
    my $job_id = $future->{id};
    $self->warn("app waiting on job $job_id");
    my $reader = $self->{reader};

    while ( not exists $self->{done}{$job_id} ) {
        my $frozen = do {
            local $/ = "\0";
            chomp( my $x = <$reader> );
            $x;
        };
        my $job;
        eval $frozen;
        $self->warn("app received job $job->{id}");
        $self->{done}{ $job->{id} } = $job->{value};
    }

    return delete $self->{done}{$job_id};
}

# Scheduler server methods (run in the child process)

# the main event loop listening for jobs and results
sub listen {
    my ($self) = @_;

    # unbuffer output stream to the parent process
    STDOUT->autoflush(1);

    # setup event watchers
    my $incoming_jobs = AnyEvent->io(
        fh   => \*STDIN,
        poll => 'r',
        cb   => sub { $self->queue_job },
    );
    my $sighup = AnyEvent->signal(
        signal => 'HUP',
        cb     => sub { $self->terminate_workers },
    );

    # wait forever for events
    AnyEvent->condvar->recv;
    die "Scheduler shouldn't have stopped listening";
}

sub is_worker_fh {
    my ( $self, $fh ) = @_;
    return exists $self->{workers}{$fh};
}

# adds a job to the queue to be processed later
sub queue_job {
    my ($self) = @_;
    my $frozen_job = $self->read_frozen_job(\*STDIN);
    push @{ $self->{job_queue} }, $frozen_job;
    $self->warn("queued a job:\n$frozen_job");
    $self->make_assignments;
    return;
}

sub read_frozen_job {
    my ( $self, $fh ) = @_;
    local $/ = "\0";
    my $frozen_job = <$fh>;
    chomp $frozen_job;
    return $frozen_job;
}

sub jobs_available {
    my ($self) = @_;
    return scalar @{ $self->{job_queue} };
}

sub next_job {
    my ($self) = @_;
    return shift @{ $self->{job_queue} };
}

sub worker_count {
    my ($self) = @_;
    return scalar keys %{ $self->{workers} };
}

sub available_worker {
    my ($self) = @_;

    # is an existing worker available?
    my @fh_ids = keys %{ $self->{workers} };
    for my $fh_id (@fh_ids) {
        my $details = $self->{workers}{$fh_id};
        if ( $details->{status} eq 'available' ) {
            return $details->{worker};
        }
    }

    # have we hit the maximum number of workers?
    if ( $self->worker_count >= $self->{allowed} ) {
        return;
    }

    # let's create a new worker
    my $worker = Thread::Lite::Worker->new;
    my $reader = $worker->reader;
    my $watcher = AnyEvent->io(
        fh   => $reader,
        poll => 'r',
        cb   => sub { $self->receive_job($reader) },
    );
    push @{ $self->{watchers} }, $watcher;
    $self->{workers}{$reader} = {
        worker => $worker,
        status => 'available',
    };
    return $worker;
}

# receives a completed job
sub receive_job {
    my ( $self, $fh ) = @_;
    my $frozen = $self->read_frozen_job($fh);

    # the associated worker is no longer busy
    $self->{workers}{$fh}{status} = 'available';

    # forward the answer to our parent process
    my $stdout = $self->{stdout};
    $stdout = $self->{stdout} = AnyEvent::Handle->new( fh => \*STDOUT )
        if not $stdout;
    $stdout->push_write("$frozen\0");
    $self->warn('received a completed job');
    $self->make_assignments;
    return;
}

# assign any pending jobs to available workers
sub make_assignments {
    my ($self) = @_;

    while ( $self->jobs_available ) {
        $self->warn('there are jobs available');
        if ( my $worker = $self->available_worker ) {
            $self->warn('and a worker available');
            $self->assign_job( $self->next_job, $worker );
        }
        else {  # no workers available to accept assignments
            $self->warn('but no worker available');
            return;
        }
    }

    return;
}

sub assign_job {
    my ( $self, $frozen_job, $worker ) = @_;
    $self->warn( sprintf("assigning job to %s", $worker->reader) );

    $self->{workers}{ $worker->reader }{status} = 'busy';
    $worker->assign_job($frozen_job);
    return;
}

sub terminate_workers {
    my ($self) = @_;

    kill 'HUP', map { $_->pid } $self->workers;
    exit;
}

sub warn {
    my ($self, $msg) = @_;
    return if not $ENV{DEBUG};
    use Log::StdLog {
        level => 'trace',
        file  => '/Users/michael/src/Thread-Lite/errors.log'
    };
    print {*STDLOG} warn => "Scheduler: $msg\n";
}


1;
