use strict;
use warnings;

use Test::More;

my $numtests = int(rand(5)) + 1;

plan(tests => $numtests);

note("NOTE: @ARGV");
diag("DIAG: @ARGV");
for my $testnum (1 .. $numtests)
{
	pass($testnum . " (" . __FILE__ . ":" . __LINE__ . ")");
	sleep(int(rand(3)));
}

done_testing();
