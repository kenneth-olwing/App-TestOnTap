use strict;
use warnings;

$| = 1;

print "1..3\n";

my $product = sqrt(2) * sqrt(2);

my $not = $product == 2 ? '' : 'not ';
print "${not}ok 1 - $product equals 2\n";

my $intproduct = int($product);
$not = $intproduct == 2 ? '' : 'not ';
print "${not}ok 2 - Product equals 2 (integer number)\n";

my $stringproduct = sprintf("%.16f", $product);
$not = $stringproduct eq '2.0000000000000000' ?  '' : 'not ';
print "${not}ok 3 - Product equals 2.0000000000000000 (decimal string)\n";
