use strict;
use warnings;
use File::Find;

my $dir = shift;
my @interesting;
find({ wanted => \&wanted, no_chdir => 1 }, $dir );
print "$_\n" for @interesting;

sub wanted {
    my $file = $File::Find::name;
    return if -d $file;
    open my $fh, '<', $file or die "Can't open $file: $!";
    local $/;
    my $content = <$fh>;
    push @interesting, $file if $content =~ /\bfuture\b/i;
}
