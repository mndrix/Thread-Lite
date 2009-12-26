#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Thread::Lite' );
}

diag( "Testing Thread::Lite $Thread::Lite::VERSION, Perl $], $^X" );
