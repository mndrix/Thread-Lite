use strict;
use warnings;
use Test::More tests => 10;
use Sub::Future;

# a scalar return value with explicit usage
{
    my $value = future { 'something' };
    is $value->value, 'something', 'a quick scalar return';
    is $value->value, 'something', '... still has the same value';
}

# a scalar return value with implicit usage
{
    my $value = future { 'something' };
    is "$value", 'something', 'a quick scalar return';
    is "$value", 'something', '... still has the same value';
}

# ref return values
{
    my $value = future { ['one', 'two'] };
    is_deeply [ @$value ], ['one', 'two'], 'a quick ARRAY return';
    is_deeply [ @$value ], ['one', 'two'], '... still has the same value';
}
{
    my $value = future { { one => 'two' } };
    is_deeply { %$value }, { one => 'two' }, 'a quick HASH return';
    is_deeply { %$value }, { one => 'two' }, '... still has the same value';
}

# make sure concurrency is happening
{
    my $start = time;
    my $later = future { sleep 3; return scalar time; };
    cmp_ok(time - $start, '<=', 1, 'future returns instantly');
    cmp_ok($later, '>', 2, 'blocks until the future is ready');
}
