use strict;
use warnings;
use Sub::Future;

my @fs;
for ( 1 .. 100 ) {
    my $f = future { 1 };
    push @fs, $f;
}

while ( my $f = shift @fs ) { $f->value }
