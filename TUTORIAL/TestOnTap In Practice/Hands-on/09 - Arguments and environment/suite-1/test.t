print "1..1\n";

$argcount = @ARGV;
print "# Begin arguments ($argcount)\n";
print "#   $_\n" foreach @ARGV;
print "# End arguments\n";

$envcount = keys(%ENV);
print "# Begin environment ($envcount)\n";
print "#   $_=$ENV{$_}\n" foreach sort(keys(%ENV));
print "# End environment\n";

print "ok 1\n";
