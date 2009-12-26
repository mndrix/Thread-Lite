use strict;
use warnings;
use Test::More tests => 1;
use Thread::Lite;

my @expected = map { $_*2 } 1..500;

my @got;
for my $i (1..500) {
    my $f = future { $i*2 };
    push @got, $f;
}
use Log::StdLog {
    level => 'trace',
    file  => '/Users/michael/src/Thread-Lite/errors.log'
};
print {*STDLOG} warn => "Test: asking for values now\n";
@got = map { $_->value } @got;

is_deeply \@got, \@expected, 'parallel map';
