use strict;
use warnings;
use File::Find;

my $dir = shift;
find({ wanted => sub {}, no_chdir => 1 }, $dir );

sub wanted {
    my $file = $File::Find::name;
    return if -d $file;
    return;
}
