package Sub::Future::Scheduler;
use strict;
use warnings;

use IPC::Open2 qw();
use Data::Dump::Streamer;
use Sub::Future::Worker;
use IO::Select;
use Sys::CPU qw();

sub new {
    my $class = shift;

    my ( $writer, $reader );
    my $pid = IPC::Open2::open2( $reader, $writer, '-' );

    # in the parent
    return bless {
        pid         => $pid,
        reader      => $reader,
        writer      => $writer,
        next_job_id => 1,
    }, $class if $pid;

    # in the scheduler itself (child)
    my $select = IO::Select->new( \*STDIN );
    my $self = bless {
        select => $select,
        workers => {
            allowed   => Sys::CPU::cpu_count(),
            available => [],
            busy      => [],
            all       => [],
        },
    }, $class;
    local $SIG{HUP} = sub { $self->terminate_workers; exit };
    $self->listen;
}

sub workers {
    my ($self) = @_;
    return @{ $self->{workers}{all} };
}

# Scheduler client methods (run in the parent process)

# schedules a new job for running and returns a Sub::Future object
sub start {
    my ( $self, $code ) = @_;

    # send the job to the scheduler server process
    my $job = {
        id   => $self->{next_job_id}++,
        code => $code,
    };
    local $| = 1;
    Dump($job)->Names('job')->To( $self->{writer} )->Out;
    my $writer = $self->{writer};
    print $writer "\0";

    return bless { id => $job->{id} }, 'Sub::Future';
}

# wait for a specific future's answer to be available
sub wait_on {
    my ( $self, $future ) = @_;
    my $job_id = $future->{id};
    my $reader = $self->{reader};

    while ( not exists $self->{done}{$job_id} ) {
        my $frozen = do { local $/ = "\0"; <$reader> };
        my $job;
        eval $frozen;
        $self->{done}{ $job->{id} } = $job->{value};
    }

    return delete $self->{done}{$job_id};
}

# Scheduler server methods (run in the child process)

# the main event loop listening for jobs and results
sub listen {
    my ($self) = @_;

    my $select = $self->{select};
    while ( my @ready = $select->can_read ) {
        READY:
        for my $fh (@ready) {
            my $frozen = do { local $/ = "\0"; <$fh> };
            warn "Scheduler got frozen job: $frozen\n" if $ENV{DEBUG};
            if ( $fh eq \*STDIN ) {    # a new job arriving
                warn "It's a new job\n" if $ENV{DEBUG};
                $self->new_job($frozen);
            }
            else {                     # a completed job arriving
                warn "It's a completed job\n" if $ENV{DEBUG};
                local $| = 1;
                warn "Scheduler sending completed job: $frozen\n"
                  if $ENV{DEBUG};
                print $frozen;         # send result to scheduler client
                $self->job_completed($fh);
            }
        }

        $self->make_assignments;
        warn "Scheduler is listening again\n" if $ENV{DEBUG};
    }

    die "Scheduler shouldn't have stopped listening";
}

# handles a newly arrived job
sub new_job {
    my ( $self, $frozen_job ) = @_;
    
    if ( my $worker = shift @{ $self->{workers}{available} } ) {
        push @{ $self->{workers}{busy} }, $worker;
        $worker->assign_job($frozen_job);
        return;
    }

    # queue the job if we can't make more workers
    if ( @{ $self->{workers}{all} } >= $self->{workers}{allowed} ) {
        push @{ $self->{job_queue} }, $frozen_job;
        return;
    }

    # create a new worker and assign the job
    my $worker = Sub::Future::Worker->new;
    push @{ $self->{workers}{all} },  $worker;
    push @{ $self->{workers}{busy} }, $worker;
    $worker->assign_job($frozen_job);
    $self->{select}->add( $worker->reader );
    return;
}

# assign any pending jobs to available workers
sub make_assignments {
    my ($self) = @_;
    while ( @{ $self->{workers}{available} } ) {
        my $frozen_job = shift @{ $self->{job_queue} }
            or last;
        my $worker = shift @{ $self->{workers}{available} };
        push @{ $self->{workers}{busy} }, $worker;
        $worker->assign_job($frozen_job);
        return;
    }

    return;
}

# marks a specific worker as finished with its current assignment
sub job_completed {
    my ( $self, $fh ) = @_;
    my $busy = $self->{workers}{busy};

    for my $i ( 0 .. $#$busy ) {
        warn "Scheduler comparing FHs: $fh and ", $busy->[$i]->reader, "\n"
          if $ENV{DEBUG};
        if ( $fh eq $busy->[$i]->reader ) {
            my $worker = splice @$busy, $i, 1;
            push @{ $self->{workers}{available} }, $worker;
            return;
        }
    }

    die "Couldn't find the worker for FH $fh";
}

sub terminate_workers {
    my ($self) = @_;

    kill 'HUP', map { $_->pid } $self->workers;
    return;
}

1;
