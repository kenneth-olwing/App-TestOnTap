use strict;
use warnings;

use FindBin qw($Bin);

use lib "$Bin/lib";

use TestUtils;

use Test::More tests => 2;

my ($ret, $stdout, $stderr) = TestUtils::xeqsuite(['--verbose']);

is($ret, 1, "Exited with 1");
like($stderr->[0], qr/^WARNING: Error 42 when running postprocess command: This is postprocess$/, "saw postproc warning");

done_testing();
