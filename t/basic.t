use strict;
use warnings;
use Test::More tests => 6;
use Sub::Future;

# a scalar return value
{
    my $value = future { 'something' };
    is "$value", 'something', 'a quick scalar return';
    is "$value", 'something', '... still has the same value';
}

# a reference return value
{
    my $value = future { ['one', 'two'] };
    is_deeply [ @$value ], ['one', 'two'], 'a quick reference return';
    is_deeply [ @$value ], ['one', 'two'], '... still has the same value';
}

{
    my $start = time;
    my $later = future { sleep 3; return scalar time; };
    cmp_ok(time - $start, '<=', 1, 'future returns instantly');
    cmp_ok($later, '>', 2, 'blocks until the future is ready');
}
