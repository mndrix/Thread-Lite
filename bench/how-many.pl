use strict;
use warnings;
use Sub::Future;

for ( 1 .. 10_000 ) {
    my $f = future { 1 };
    $f->value;
}
