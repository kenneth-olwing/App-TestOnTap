package App::TestOnTap::Config;

use strict;
use warnings;

use App::TestOnTap::Util qw(slashify);
use App::TestOnTap::_vars;

use Config::Std;
use Grep::Query;
use UUID::Tiny qw(:std);

# CTOR
#
sub new
{
	my $class = shift;
	my $path = shift;
	my $userExecMapFile = shift;

	my $configFilePath = -f $path ? $path : slashify("$path/" . getName());
	
	my $self = bless({}, $class);
	$self->__readCfgFile($configFilePath, $userExecMapFile);

	return $self;
}

# read the raw Config::Std file and fill in
# data fields
#
sub __readCfgFile
{
	my $self = shift;
	my $configFilePath = $App::TestOnTap::_vars::FORCED_CONFIG_FILE || shift;
	my $userExecMapFile = shift;
	
	my $cfg;
	if (-e $configFilePath && !$App::TestOnTap::_vars::IGNORE_CONFIG_FILE)
	{
		read_config($configFilePath, $cfg);
	}
	else
	{
		my $id = create_uuid_as_string();
		warn("WARNING: No configuration file found, using blank with generated id '$id'!\n");
		$cfg->{''}->{id} = $id; 
	}

	# pick the necessities from the blank section
	#
	my $blankSection = $cfg->{''} || {};

	# a valid uuid is required
	#
	my $id = $blankSection->{id} || '';
	die("Invalid suite id: '$id'") unless $id =~ /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/;
	$self->{id} = $id;
	
	# an optional filter to select parts while scanning suite root
	#
	# ensure it's in text form - an array is simply joined using newlines
	#
	my $include = $blankSection->{include};
	if (defined($include))
	{
		$include = join("\n", @$include) if ref($include) eq 'ARRAY';
		$include = Grep::Query->new($include);
	}
	$self->{include} = $include;

	# an optional filter to check if a test can run in parallel (with any other test) 
	#
	# ensure it's in text form - an array is simply joined using newlines
	#
	my $parallelizable = $blankSection->{parallelizable};
	if (defined($parallelizable))
	{
		$parallelizable = join("\n", @$parallelizable) if ref($parallelizable) eq 'ARRAY';
		$parallelizable = Grep::Query->new($parallelizable);
	}
	$self->{parallelizable} = $parallelizable;

	# set up execmap, possibly as a delegate from a user defined one 
	#
	# a non-existing section will cause a default execmap
	#
	my $execMap = App::TestOnTap::ExecMap->new($cfg->{EXECMAP});
	$execMap = App::TestOnTap::ExecMap->newFromFile($userExecMapFile, $execMap) if $userExecMapFile;
	$self->{execmap} = $execMap; 

	my %depRules;

	if (!$App::TestOnTap::_vars::IGNORE_DEPENDENCIES)
	{
		# find all dependency sections
		#
		my $depRx = qr(^\s*DEPENDENCY\s+(.+?)\s*$);
		foreach my $depRuleSectionName (grep(/$depRx/, keys(%$cfg)))
		{
			$depRuleSectionName =~ /$depRx/;
			my $depRuleName = $1;
			
			# all dep sections requires match/dependson Grep::Query queries
			# in case they're written as arrays, just join using newlines
			#
			foreach my $key (qw( match dependson ))
			{
				my $value = $cfg->{$depRuleSectionName}->{$key}; 
				die("Missing key '$key' in dependency rule section '$depRuleName'\n") unless defined($value);
				$value = join("\n", @$value) if ref($value) eq 'ARRAY';
				$depRules{$depRuleName}->{$key} = Grep::Query->new($value);
			}
		}
	}

	$self->{deprules} = \%depRules;
}

sub getName
{
	# works as both class/instance/sub...
	#
	return $App::TestOnTap::_vars::CONFIG_FILE_NAME;
}

sub getId
{
	my $self = shift;
	
	return $self->{id};
}

sub include
{
	my $self = shift;
	my $test = shift;
	
	return
		$self->{include}
			? $self->{include}->qgrep($test)
			: 1;
}

sub hasParallelizableRule
{
	my $self = shift;
	
	return $self->{parallelizable} ? 1 : 0
}

sub parallelizable
{
	my $self = shift;
	my $test = shift;
	
	return
		$self->{parallelizable}
			? $self->{parallelizable}->qgrep($test)
			: 0;
}

sub mapsExtension
{
	my $self = shift;
	my $ext = shift;

	return $self->{execmap}->mapsExtension($ext);	
}

sub getCommandForExtension
{
	my $self = shift;
	my $ext = shift;

	return $self->{execmap}->getCommandForExtension($ext);	
}

sub getDependencyRuleNames
{
	my $self = shift;
	
	return keys(%{$self->{deprules}});
}

sub getMatchesAndDependenciesForRule
{
	my $self = shift;
	my $depRuleName = shift;
	my $tests = shift;
	
	my @matches = $self->{deprules}->{$depRuleName}->{match}->qgrep(@$tests);
	die("No tests selected by 'match' in dependency rule '$depRuleName'\n") unless @matches;

	my @dependencies = $self->{deprules}->{$depRuleName}->{dependson}->qgrep(@$tests);
	die("No tests selected by 'dependson' in dependency rule '$depRuleName'\n") unless @dependencies;
	 
	return (\@matches, \@dependencies);
}

1;
