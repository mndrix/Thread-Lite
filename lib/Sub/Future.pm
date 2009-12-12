package Sub::Future;

use warnings;
use strict;
use base qw( Exporter );
use Storable qw( store retrieve );

BEGIN {
    our @EXPORT = qw( spawn );
};

=head1 NAME

Sub::Future - concurrency with futures

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use Sub::Future;
    my $value = future {
        # long running computation goes here
    };
    
    # do some things that don't require $value
    
    # block until the long-running computation is done
    print "Long computation returned: $value\n";

=head1 EXPORT

=head2 future

This function is exported by default.

=cut

sub future(&) {
    my ($code) = @_;

    # open a temporary file for interprocess communication
    my ( undef, $filename ) = tempfile( UNLINK => 0 );
    
    # create a new process to handle the spawned calculation
    my $pid = fork;
    die "Unable to fork: $!\n" if not defined $pid;

    # the child process performs the calculation
    if ( not $pid ) {
        my $value = $code->();
        store( { returned => $value }, $filename );
        exit;    # the calculation is finished
    }

    # the parent process returns a thunk immediately
    return lazy {
        my $harvested_pid = waitpid $pid, 0;
        die "Harvested the wrong child? $pid vs $harvested_pid"
            if $pid != $harvested_pid;
        my $value = retrieve($filename);
        unlink $filename;
        return $value->{returned};
    };
}

=head1 AUTHOR

Michael Hendricks, C<< <michael at ndrix.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-future at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sub-Future>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sub::Future

=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Michael Hendricks, all rights reserved.

This program is released under the following license: mit


=cut

1; # End of Sub::Future
