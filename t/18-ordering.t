use strict;
use warnings;

use FindBin qw($Bin);

use lib "$Bin/lib";

use TestUtils;

use Test::More tests => 27;

my ($ret, $stdout, $stderr) = TestUtils::xeqsuite('--verbose');

is($ret, 0, "Exited with 0");
like($stdout->[13], qr/^Files=3, Tests=3, /, "Three tests found");
is($stdout->[14], "Result: PASS", "Passed");

$App::TestOnTap::_dbgvars::CONFIG_FILE_NAME = 'alphabetic_config.testontap';
($ret, $stdout, $stderr) = TestUtils::xeqsuite('--verbose');

is($ret, 0, "Exited with 0");
like($stdout->[0], qr/^t1\.pl /, "t1 first");
like($stdout->[4], qr/^t10\.pl /, "t10 in the middle");
like($stdout->[8], qr/^t2\.pl /, "t2 last");
like($stdout->[13], qr/^Files=3, Tests=3, /, "Three tests found");
is($stdout->[14], "Result: PASS", "Passed");

($ret, $stdout, $stderr) = TestUtils::xeqsuite('--verbose', '--order', 'ralphabetic');

is($ret, 0, "Exited with 0");
like($stdout->[0], qr/^t2\.pl /, "t2 first");
like($stdout->[4], qr/^t10\.pl /, "t10 in the middle");
like($stdout->[8], qr/^t1\.pl /, "t1 last");
like($stdout->[13], qr/^Files=3, Tests=3, /, "Three tests found");
is($stdout->[14], "Result: PASS", "Passed");

$App::TestOnTap::_dbgvars::CONFIG_FILE_NAME = 'natural_config.testontap';
($ret, $stdout, $stderr) = TestUtils::xeqsuite('--verbose');

is($ret, 0, "Exited with 0");
like($stdout->[0], qr/^t1\.pl /, "t1 first");
like($stdout->[4], qr/^t2\.pl /, "t2 in the middle");
like($stdout->[8], qr/^t10\.pl /, "t10 last");
like($stdout->[13], qr/^Files=3, Tests=3, /, "Three tests found");
is($stdout->[14], "Result: PASS", "Passed");

($ret, $stdout, $stderr) = TestUtils::xeqsuite('--verbose', '--order', 'rnatural');

is($ret, 0, "Exited with 0");
like($stdout->[0], qr/^t10\.pl /, "t10 first");
like($stdout->[4], qr/^t2\.pl /, "t2 in the middle");
like($stdout->[8], qr/^t1\.pl /, "t1 last");
like($stdout->[13], qr/^Files=3, Tests=3, /, "Three tests found");
is($stdout->[14], "Result: PASS", "Passed");

done_testing();
