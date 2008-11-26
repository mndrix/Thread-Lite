package Data::Future;

use warnings;
use strict;
use base qw( Exporter );
use overload '""' => 'force', fallback => 1;
use Data::Thunk qw( lazy );
use threads;

BEGIN {
    our @EXPORT = qw( spawn );
};

=head1 NAME

Data::Future - Futures for Perl

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use Data::Future;
    my $value = future {
        # long running computation goes here
    };
    
    # do some things that don't require $value
    
    # block until the long-running computation is done
    print "Long computation returned: $value\n";

=head1 EXPORT

=head2 spawn

This function is exported by default.

=cut

sub spawn(&) {
    my ($code) = @_;
    my $thread = threads->create($code);

    return lazy {
        my $value = $thread->join;
        if ( my $error = $thread->error ) {
            die $error;
        }
        return $value;
    };
}

=head1 AUTHOR

Michael Hendricks, C<< <michael at ndrix.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-future at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Future>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::Future


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Future>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-Future>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-Future>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-Future/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Michael Hendricks, all rights reserved.

This program is released under the following license: mit


=cut

1; # End of Data::Future
