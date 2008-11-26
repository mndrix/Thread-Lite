#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Data::Future' );
}

diag( "Testing Data::Future $Data::Future::VERSION, Perl $], $^X" );
