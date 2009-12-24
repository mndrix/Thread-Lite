package Sub::Future;

use warnings;
use strict;
use base qw( Exporter );
use Sub::Future::Scheduler;
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

our $VERSION = '0.02';

=head1 SYNOPSIS

    use Sub::Future;
    my $value = future {
        # long running computation goes here
        return 'result goes here';
    };
    
    # do some things that don't require $value
    # while $value is calculated in parallel
    
    # use the computation's return value (blocks if necessary)
    print "Long computation returned: $value\n";

=head1 EXPORTED

=head2 future $coderef

Starts executing C<$coderef> in parallel and returns immediately.  The
returned value can be used at any time to retrieve the value calculated by
C<$coderef>.  If the parallel calculation isn't done, using the value blocks
until the value is ready.

=cut

our $scheduler;
sub future(&) {
    my ($code) = @_;
#   return bless { code => $code }, __PACKAGE__;
    $scheduler = Sub::Future::Scheduler->new if not $scheduler;
    return $scheduler->start($code);
}
END {
    kill HUP => $scheduler->{pid} if $scheduler;
}

=head1 METHODS

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

    # do we already have the value locally?
    if ( exists $self->{value} ) {
        my $v = $self->{value};
        bless $self, $class;
        return $v;
    }

    # no, so wait for the scheduler to provide the answer
    my $v = $self->{value} = $scheduler->wait_on($self);
#   my $v = $self->{value} = $self->{code}->();
    bless $self, $class;
    return $v;
}

=head1 AUTHOR

Michael Hendricks, C<< <michael@ndrix.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-future at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sub-Future>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 VERSION CONTROL

git://github.com/mndrix/Sub-Future.git

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sub::Future

=head1 SEE ALSO

L<http://github.com/mndrix/Sub-Future>

L<http://en.wikipedia.org/wiki/Futures_and_promises>

L<subs::parallel>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Michael Hendricks, all rights reserved.

This program is released under the following license: mit


=cut

1; # End of Sub::Future
