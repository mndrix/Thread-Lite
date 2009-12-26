use strict;
use warnings;
use File::Find;
use Sub::Future;

my $dir = shift;
my @futures;
find({ wanted => \&wanted, no_chdir => 1 }, $dir );
for my $f (@futures) {
    my $file = $f->value;
    next if not defined $file;
    print "$file\n";
}

sub wanted {
    my $file = $File::Find::name;
    return if -d $file;
    my $f = future {
        open my $fh, '<', $file or die "Can't open $file: $!";
        local $/;
        my $content = <$fh>;
        return $file if $content =~ /\bfuture\b/i;
        return;
    };
    push @futures, $f;
}
