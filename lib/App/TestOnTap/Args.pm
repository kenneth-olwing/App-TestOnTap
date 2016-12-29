# Parses a commandline packaged as a list (e.g. normally just pass @ARGV)
# and processes it into real objects for later use by various functions
# in the testontap universe
#
package App::TestOnTap::Args;

use strict;
use warnings;

use App::TestOnTap::Util qw(slashify);
use App::TestOnTap::ExecMap;
use App::TestOnTap::Config;
use App::TestOnTap::WorkDirManager;

use Getopt::Long qw(GetOptionsFromArray :config require_order no_ignore_case);
use Pod::Usage;
use Pod::Find qw(pod_where);
use Grep::Query;
use File::Spec;
use File::Path;
use UUID::Tiny qw(:std);

# CTOR
#
sub new
{
	my $class = shift;
	my $version = shift;

	my $self = bless( { id => create_uuid_as_string() }, $class);
	$self->__parseArgv($version, @_);

	return $self;
}

sub __parseArgv
{
	my $self = shift;
	my $version = shift;
	my @argv = @_;
	
	my %rawOpts =
		(
			usage => 0,
			help => 0,
			manual => 0,
			version => 0,
			execmap => undef,			# no execmap from file to apply
			define => {},				# arbitrary key=value defines
			include => undef,			# no filter (select all tests)
			jobs => 1,					# run only one job at a time (no parallelism)
			timer => 0,					# don't show timing output
			workdirectory => undef,		# explicit directory to use
			savedirectory => undef,		# don't save results (unless -archive is used)
			archive => 0,				# don't save results as archive
			verbose => 0,				# don't let through output from tests
		);
		
	my @specs =
		(
			'usage|?',
			'help',
			'manual',
			'version',
			'execmap=s',
			'define|D=s%',
			'include=s',
			'jobs=i',
			'timer!',
			'workdirectory=s',
			'savedirectory=s',
			'archive!',
			'verbose!'
		);

	my $argsPodInput = pod_where( { -inc => 1 }, 'App::TestOnTap::Args');
	my $manualPodInput = pod_where( { -inc => 1 }, 'App::TestOnTap');
	 
	# for consistent error handling below, trap getopts problems
	# 
	eval
	{
		local $SIG{__WARN__} = sub { die(@_) };
		GetOptionsFromArray(\@argv, \%rawOpts, @specs)
	};
	if ($@)
	{
		pod2usage(-input => $argsPodInput, -message => "Failure parsing options:\n  $@", -exitval => 255, -verbose => 0);
	}

	# if any of the doc switches made, display the pod
	#
	pod2usage(-input => $manualPodInput, -exitval => 0, -verbose => 2, -noperldoc => 1) if $rawOpts{manual};
	pod2usage(-input => $argsPodInput, -exitval => 0, -verbose => 2, -noperldoc => 1) if $rawOpts{help};
	pod2usage(-input => $argsPodInput, -exitval => 0, -verbose => 0) if $rawOpts{usage};
	pod2usage(-message => "$0 version $version", -exitval => 0, -verbose => 99, -sections => '_') if $rawOpts{version};

	# create the user include filter for pruning the list of tests later
	#
	eval
	{
		$self->{include} =
			defined($rawOpts{include})
				? Grep::Query->new($rawOpts{include})
				: undef;
	};
	if ($@)
	{
		pod2usage(-message => "Failure creating include filter:\n  $@", -exitval => 255, -verbose => 0);
	}

	# make sure we have a valid jobs value
	#
	pod2usage(-message => "Invalid -jobs value: '$rawOpts{jobs}'", -exitval => 255, -verbose => 0) if $rawOpts{jobs} < 1;
	$self->{jobs} = $rawOpts{jobs};
	
	# set up savedir, if given - or, if archive is given fall back to current dir
	#
	if (defined($rawOpts{savedirectory}) || $rawOpts{archive})
	{
		eval
		{
			$self->{savedirectory} = slashify(File::Spec->rel2abs($rawOpts{savedirectory} || '.'));
			die("The -savedirectory '$self->{savedirectory}' exists but is not a directory\n") if (-e $self->{savedirectory} && !-d $self->{savedirectory});
			if (!-e $self->{savedirectory})
			{
				mkpath($self->{savedirectory}) or die("Failed to create -savedirectory '$self->{savedirectory}': $!\n");
			}
		};
		if ($@)
		{
			pod2usage(-message => "Failure setting up the save directory:\n  $@", -exitval => 255, -verbose => 0);
		}
	}

	# make sure we have the suite root and that it exists as directory
	#
	eval
	{
		die("No suite root provided!\n") unless @argv;
		$self->{suiteroot} = slashify(File::Spec->rel2abs(shift(@argv)));
		die("Not a directory: '$self->{suiteroot}'\n") unless -d $self->{suiteroot};
	};
	if ($@)
	{
		pod2usage(-message => "Failure getting suite root directory:\n  $@", -exitval => 255, -verbose => 0);
	}

	# we want a config in the suite root
	#
	eval
	{
		$self->{config} = App::TestOnTap::Config->new($self->{suiteroot}, $rawOpts{execmap}); 
	};
	if ($@)
	{
		pod2usage(-message => "Failure handling config in '$self->{suiteroot}':\n  $@", -exitval => 255, -verbose => 0);
	}

	# set up the workdir manager
	#
	eval
	{
		$self->{workdirmgr} = App::TestOnTap::WorkDirManager->new($rawOpts{workdirectory}, $self->{suiteroot});
	};
	if ($@)
	{
		pod2usage(-message => "Failure setting up the working directory:\n  $@", -exitval => 255, -verbose => 0);
	};

	# simple copies
	#
	$self->{$_} = $rawOpts{$_} foreach (qw(verbose archive defines timer));

	# keep the rest of the argv as-is
	#
	$self->{argv} = \@argv;
	
	# final sanity checks
	#
	if ($self->{jobs} > 1 && !$self->{config}->hasParallelizableRule())
	{
		warn("WARNING: No 'parallelizable' rule found ('--jobs $self->{jobs}' has no effect); all tests will run serially!\n");
	}
}

sub getArgv
{
	my $self = shift;
	
	return $self->{argv};
}

sub getId
{
	my $self = shift;
	
	return $self->{id};
}

sub getJobs
{
	my $self = shift;
	
	return $self->{jobs};
}

sub getTimer
{
	my $self = shift;
	
	return $self->{timer};
}

sub getArchive
{
	my $self = shift;
	
	return $self->{archive};
}

sub getDefines
{
	my $self = shift;
	
	return $self->{defines};
}

sub getVerbose
{
	my $self = shift;
	
	return $self->{verbose};
}

sub getSuiteRoot
{
	my $self = shift;
	
	return $self->{suiteroot};
}

sub getSaveDir
{
	my $self = shift;
	
	return $self->{savedirectory};
}

sub getWorkDirManager
{
	my $self = shift;
	
	return $self->{workdirmgr};
}

sub getConfig
{
	my $self = shift;
	
	return $self->{config};
}

sub include
{
	my $self = shift;
	my $tests = shift;
	
	return
		$self->{include}
			? [ $self->{include}->qgrep(@$tests) ]
			: undef;
}

1;
