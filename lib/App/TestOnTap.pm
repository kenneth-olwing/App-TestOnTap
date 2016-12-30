package App::TestOnTap;

use 5.010;

use strict;
use warnings;

our $VERSION = '0.001';
my $version = $VERSION;
$VERSION = eval $VERSION;

use App::TestOnTap::Args;
use App::TestOnTap::Harness;

# These are (known) implicit dependencies, and listing them like this
# allows scanners like perlapp to pick up on them
# 
require TAP::Parser if 0;
require TAP::Parser::Aggregator if 0;
require TAP::Parser::Multiplexer if 0;
require TAP::Formatter::Console::ParallelSession if 0;

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
