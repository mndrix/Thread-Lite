use strict;
use warnings;
use File::Find;
use Thread::Lite;

my $dir = shift;
my @threads;
find({ wanted => \&wanted, no_chdir => 1 }, $dir );
for my $t (@threads) {
    my $file = $t->join;
    next if not defined $file;
    print "$file\n";
}

sub wanted {
    my $file = $File::Find::name;
    return if -d $file;
    my $f = async {
        open my $fh, '<', $file or die "Can't open $file: $!";
        local $/;
        my $content = <$fh>;
        return $file if $content =~ /\bfuture\b/i;
        return;
    };
    push @futures, $f;
}
