use strict;
use warnings;
use Thread::Lite;

my @fs;
for ( 1 .. 100 ) {
    my $f = async { 1 };
    push @fs, $f;
}

while ( my $f = shift @fs ) { $f->join }
