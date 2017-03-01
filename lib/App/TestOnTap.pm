package App::TestOnTap;

use 5.010_001;

use strict;
use warnings;

our $VERSION = '0.023';
my $version = $VERSION;
$VERSION = eval $VERSION;

use App::TestOnTap::Args;
use App::TestOnTap::Harness;
use App::TestOnTap::Util qw($IS_PACKED);

# These are (known) implicit dependencies, and listing them like this
# allows scanners like perlapp to pick up on them
# 
require TAP::Parser if 0;
require TAP::Parser::Aggregator if 0;
require TAP::Parser::Multiplexer if 0;
require TAP::Formatter::Console::ParallelSession if 0;

# this looks weird, I know - see https://rt.cpan.org/Public/Bug/Display.html?id=56862
#
# I seem to hit the problem with "Warning: Name "Config::Std::Hash::DEMOLISH" used only once..."
# when running a Par::Packer binary but not when as a 'normal' script.
#
# The below incantation seem to get rid of that, at least for now. Let's see if it reappears... 
#
if ($IS_PACKED)
{
	require Config::Std;
	Config::Std->import('read_config');
	my $dummy1 = '';
	Config::Std::read_config(\$dummy1, my %cfg);
	my $dummy2 = *Config::Std::Hash::DEMOLISH;
	my $dummy3 = *Config::Std::Hash::DEMOLISH;
}

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
