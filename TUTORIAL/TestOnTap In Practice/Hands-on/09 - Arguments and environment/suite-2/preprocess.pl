use strict;
use warnings;

# only print either of the argv/env blocks if we detect a need to fix them
# also consider that if you print anything, everything must be printed

if (grep(/FIXME/, @ARGV))
{
	print "# BEGIN ARGV\n";
	foreach my $arg (@ARGV)
	{
		$arg =~ s/FIXME/DONE/g;
		print "$arg\n";
	}
	print "# END ARGV\n";
}

if (grep(/FIXME/, values(%ENV)))
{
	print "# BEGIN ENV\n";
	foreach my $k (keys(%ENV))
	{
		$ENV{$k} =~ s/FIXME/DONE/g;
		print "$k=$ENV{$k}\n";
	}
	print "# END ENV\n";
}
