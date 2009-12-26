use strict;
use warnings;
use File::Find;
use IPC::Open2;
use IO::Select;
use feature qw( state );

my $dir = shift;

# fork a couple kids to do the hard work
my @kids;
my $select = IO::Select->new;
for ( 1..2 ) {
    my ( $reader, $writer );
    my $pid = open2 $reader, $writer, '-';
    if ($pid) { # parent
        $select->add($reader);
        push @kids, $writer;
    }
    else { # child
        while ( my $file = <STDIN> ) {
            chomp $file;
            exit if $file eq 'quit...';
            open my $fh, '<', $file or die "Can't open $file: $!";
            my $content = do { local $/; <$fh> };
            print "$file\n" if $content =~ /\bfuture\b/i;
        }
    }
}

# hand files to the kids to process
my @interesting;
find({ wanted => \&wanted, no_chdir => 1 }, $dir );
print $_ "quit...\n" for @kids;
for my $reader ( $select->handles ) {
    while ( my $file = <$reader> ) {
        chomp $file;
        push @interesting, $file;
    }
}
print "$_\n" for @interesting;

sub wanted {
    state $i = 0;
    my $file = $File::Find::name;
    return if -d $file;

    # send the file to a kid for processing
    my $writer = $kids[$i];
    print $writer "$file\n";
    $i = ($i+1) % 2;

    # any answers for us yet?
    while ( my @fhs = $select->can_read(0) ) {
        for my $fh (@fhs) {
            chomp( my $file = <$fh> );
            push @interesting, $file;
        }
    }

    return;
}

