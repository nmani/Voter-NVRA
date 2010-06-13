#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Voter::NVRA' ) || print "Bail out!
";
}

diag( "Testing Voter::NVRA $Voter::NVRA::VERSION, Perl $], $^X" );
