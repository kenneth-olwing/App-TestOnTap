use strict;
use warnings;

use FindBin qw($Bin);

use lib "$Bin/lib";

use TestUtils;

use Test::More tests => 10;

my ($ret, $stdout, $stderr) = TestUtils::xeqsuite([qw(--no-harness)]);

is($ret, 0, "Exited with 0");
like($stderr->[0], qr/^WARNING: No id found, using generated '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}'!$/, "Generated id");
like($stderr->[1], qr/^WARNING: missing execmap, using internal!$/, "default execmap");
like($stdout->[0], qr/^#+$/, "top delimiter");
like($stdout->[1], qr/^Run test 'normal.pl' using:$/, "info");
like($stdout->[4], qr/^-+$/, "bottom delimiter");
like($stdout->[5], qr/^1..2$/, "plan");
like($stdout->[6], qr/^ok 1 - yes, one equals one$/, "test 1");
like($stdout->[7], qr/^# note$/, "note");
like($stdout->[8], qr/^ok 2 - yes, two equals two$/, "test 2");

done_testing();
