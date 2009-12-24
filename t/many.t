use strict;
use warnings;
use Test::More tests => 1;
use Sub::Future;

my @expected = map { $_*2 } 1..100;

my @got;
for my $i (1..100) {
    my $f = future { $i*2 };
    push @got, $f;
}
use Log::StdLog {
    level => 'trace',
    file  => '/Users/michael/src/Sub-Future/errors.log'
};
print {*STDLOG} warn => "Test: asking for values now\n";
@got = map { $_->value } @got;

is_deeply \@got, \@expected, 'parallel map';
