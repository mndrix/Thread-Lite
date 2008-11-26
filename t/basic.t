use strict;
use warnings;
use Test::More tests => 4;
use Data::Future;

{
    my $value = spawn { 'something' };
    is $value, 'something', 'a quick return';
    is $value, 'something', 'still has the same value';
}

{
    my $start = time;
    my $later = spawn { sleep 3; return scalar time; };
    cmp_ok(time - $start, '<=', 1, 'spawn returns instantly');
    cmp_ok($later, '>', 2, 'blocks until the future is ready');
}
