use strict;
use warnings;
use Fcntl;
use File::Find;
use Coro;
use Coro::AIO;

my $dir = shift;
my @threads;
my @interesting;
find({ wanted => \&wanted, no_chdir => 1 }, $dir );
warn "About to join them all\n";
for my $f (@threads) {
    my $file = $f->join;
    push @interesting, $file if defined $file;
}
print "$_\n" for @interesting;

sub wanted {
    my $file = $File::Find::name;
    my $t = async {
        aio_stat $file;
        return if -d _;
        my $size = -s _;
        my $fh = aio_open $file, O_RDONLY, 0 or die "Can't open $file: $!";
        my $content = '';
        aio_read $fh, 0, $size, $content, 0;
        return $file if $content =~ /\bfuture\b/i;
        return;
    };
    push @threads, $t;
    while ( @threads > 10 ) {
        my $thread = shift @threads;
        my $file = $thread->join;
        push @interesting, $file if defined $file;
    }
    cede;
}

