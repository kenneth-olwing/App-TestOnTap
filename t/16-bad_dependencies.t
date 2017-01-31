use strict;
use warnings;

use FindBin qw($Bin);

use lib "$Bin/lib";

use TestUtils;

use Test::More tests => 2;

my ($ret, $stdout, $stderr) = TestUtils::xeqsuite('--verbose');

is($ret, -1, "Exited with -1");
like($stderr->[0], qr/^ERROR: Cyclic dependency detected: t1\.pl => t2\.pl => t1\.pl!$/, "Cyclic dep");

done_testing();
