use strict;
use warnings;

$| = 1;

print "1..1\n";

my $cmd = qq/perl -e "print q(Hello world\n); exit(42):"/;
my @output = qx($cmd 2>&1);
my $exitcode = $? >> 8;

my $not = $exitcode == 42 ? '' : 'not ';
print "${not}ok 1 - Correct exit code\n";

open(my $fh, '>', "$ENV{TESTONTAP_TMP_DIR}/xeqcmd.log") or die $!;
print $fh "Got exitcode: '$exitcode'\n";
print $fh "OUTPUT:\n";
print $fh "======\n";
print $fh @output;
close($fh);
