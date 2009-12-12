package Sub::Future;

use warnings;
use strict;
use base qw( Exporter );
use Storable qw( freeze thaw );
use overload
    '""'     => 'value',
    'bool'   => 'value',
    '0+'     => 'value',
    '${}'    => 'value',
    '@{}'    => 'value',
    '%{}'    => 'value',
    fallback => 1
    ;

BEGIN {
    our @EXPORT = qw( future );
};

=head1 NAME

Sub::Future - concurrency with futures

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use Sub::Future;
    my $value = future {
        # long running computation goes here
        return 'result goes here';
    };
    
    # do some things that don't require $value
    # while $value is calculated in parallel
    
    # use the computation's return value (blocking if necessary)
    print "Long computation returned: $value\n";

=head1 Exported Subroutines

=head2 future $coderef

Starts executing C<$coderef> in parallel and then returns immediately.  The
returned value can be used at any time to retrieve the value calculated by
C<$coderef>.  If the parallel calculation isn't done, using the value blocks
until the value is ready.

=cut

sub future(&) {
    my ($code) = @_;
    
    # create a new process to handle the spawned calculation
    my $pid = open my $fh, '-|';
    die "Unable to fork: $!\n" if not defined $pid;

    # the child process performs the calculation
    if ( not $pid ) {
        my $value = $code->();
        my $frozen = freeze { returned => $value };
        print $frozen;
        exit;    # the calculation is finished
    }

    # the parent process returns immediately
    return bless { pid => $pid, fh => $fh }, __PACKAGE__;
}

=head1 Methods

=head2 value

Calling this method on the object returned by L</future> returns the value
calculated by the code block.  It's usually not necessary to call this method
directly since most operations performed on the object implicitly return the
value.

=cut

sub value {
    my ($self) = @_;

    # temporarily disable overloading
    my $class = ref $self;
    bless $self, 'overload::dummy';
    if ( exists $self->{value} ) {
        my $v = $self->{value};
        bless $self, $class;
        return $v;
    }

    # retrieve the calculated value
    my $fh     = $self->{fh};
    my $frozen = do { local $/; <$fh> };
    my $v      = $self->{value} = thaw($frozen)->{returned};

    # wait on the child to exit
    my $pid = $self->{pid};
    my $harvested_pid = waitpid $pid, 0;
    if ( $pid != $harvested_pid ) {
        bless $self, $class;
        die "Harvested the wrong child? $pid vs $harvested_pid";
    }

    bless $self, $class;
    return $v;
}

=head1 AUTHOR

Michael Hendricks, C<< <michael@ndrix.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-future at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sub-Future>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sub::Future

=head1 See Also

L<http://en.wikipedia.org/wiki/Futures_and_promises>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Michael Hendricks, all rights reserved.

This program is released under the following license: mit


=cut

1; # End of Sub::Future
