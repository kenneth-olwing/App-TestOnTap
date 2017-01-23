use strict;
use warnings;

use FindBin qw($Bin);

use lib "$Bin/lib";

use TestUtils;

use Test::More tests => 8;

my ($ret, $stdout, $stderr) = TestUtils::xeqsuite('--verbose');

is($ret, 0, "Exited with 0");
like($stderr->[0], qr/^WARNING: No configuration file found, using blank with generated id '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}'!$/, "Generated id");
like($stdout->[3], qr/^not ok 2 - f # TODO TBD$/, "Expected not ok todo in 2");
like($stdout->[5], qr/^#   Failed \(TODO\) test 'f'$/, "Expected fail message");
like($stdout->[7], qr/^ok 3 - p # TODO TBD$/, "Expected ok todo in 3");
like($stdout->[15], qr/^  TODO passed:   3$/, "Expected bonus pass of 3");
like($stdout->[16], qr/^Files=1, Tests=4, /, "Only one file with four tests found");
is($stdout->[17], "Result: PASS", "Passed");

done_testing();
