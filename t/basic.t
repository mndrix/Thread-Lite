use strict;
use warnings;
use Test::More tests => 6;
use Data::Future;

# a scalar return value
{
    my $value = spawn { 'something' };
    is $value, 'something', 'a quick scalar return';
    is $value, 'something', '... still has the same value';
}

# a reference return value
{
    my $value = spawn { ['one', 'two'] };
    is_deeply $value, ['one', 'two'], 'a quick reference return';
    is_deeply $value, ['one', 'two'], '... still has the same value';
}

{
    my $start = time;
    my $later = spawn { sleep 3; return scalar time; };
    cmp_ok(time - $start, '<=', 1, 'spawn returns instantly');
    cmp_ok($later, '>', 2, 'blocks until the future is ready');
}
