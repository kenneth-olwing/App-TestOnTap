package App::TestOnTap;

use 5.010;

use strict;
use warnings;

our $VERSION = '0.001';
my $version = $VERSION;
$VERSION = eval $VERSION;

use App::TestOnTap::Args;
use App::TestOnTap::Harness;

# main entry point
#
sub main
{
	# parse raw argv
	#
	my $args = App::TestOnTap::Args->new($version, @_);

	# run all tests
	#
	my $failed = App::TestOnTap::Harness->new($args)->runtests();
	
	# in case results have been requested...
	#
	my $saveDir = $args->getSaveDir();
	if ($saveDir)
	{
		my $savePath = $args->getWorkDirManager()->saveResult($saveDir, $args->getArchive());
		print "Result saved to '$savePath'\n";
	}
	
	warn("At least $failed test(s) failed!\n") if $failed;

	return $failed;
}

1;

=head1 NAME

App::TestOnTap - Test driver 

=head1 VERSION

Version 0.001

=cut
