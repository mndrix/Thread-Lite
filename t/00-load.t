#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Sub::Future' );
}

diag( "Testing Sub::Future $Sub::Future::VERSION, Perl $], $^X" );
