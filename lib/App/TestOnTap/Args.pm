# Parses a commandline packaged as a list (e.g. normally just pass @ARGV)
# and processes it into real objects for later use by various functions
# in the testontap universe
#
package App::TestOnTap::Args;

use strict;
use warnings;

use App::TestOnTap::Util qw(slashify expandAts $IS_WINDOWS $IS_PACKED);
use App::TestOnTap::ExecMap;
use App::TestOnTap::Config;
use App::TestOnTap::WorkDirManager;

use Archive::Zip qw(:ERROR_CODES);
use FindBin qw($RealBin $Script);
use Getopt::Long qw(GetOptionsFromArray :config require_order no_ignore_case bundling);
use Pod::Usage;
use Pod::Simple::Search;
use Grep::Query;
use File::Basename;
use File::Spec;
use File::Path;
use File::Temp qw(tempdir);
use POSIX;
use UUID::Tiny qw(:std);
use LWP::Simple;

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
			skip => undef,				# no skip filter
			include => undef,			# no include filter
			jobs => 1,					# run only one job at a time (no parallelism)
			timer => 0,					# don't show timing output
			workdirectory => undef,		# explicit directory to use
			savedirectory => undef,		# don't save results (unless -archive is used)
			archive => 0,				# don't save results as archive
			v => 0,						# don't let through output from tests
			
			# hidden
			#
			_help => 0,
			_pp => 0,					# make a binary using pp
			'_pp-output' => undef,		# binary name
			'_pp-force' => 0,			# overwrite existing file
		);
		
	my @specs =
		(
			'usage|?',
			'help|h',
			'manual',
			'version',
			'execmap=s',
			'define|D=s%',
			'skip=s',
			'include=s',
			'jobs=i',
			'timer!',
			'workdirectory=s',
			'savedirectory=s',
			'archive!',
			'v|verbose+',
			
			# hidden
			#
			'_help',
			'_pp',
			'_pp-output=s',
			'_pp-force!',
		);

	my $_argsPodName = 'App/TestOnTap/_Args.pod';
	my $_argsPodInput = Pod::Simple::Search->find($_argsPodName);
	my $argsPodName = 'App/TestOnTap/Args.pod';
	my $argsPodInput = Pod::Simple::Search->find($argsPodName);
	my $manualPodName = 'App/TestOnTap.pod';
	my $manualPodInput = Pod::Simple::Search->find($manualPodName);
	
	# for consistent error handling below, trap getopts problems
	# 
	eval
	{
		@argv = expandAts('.', @argv);
		$self->{fullargv} = [ @argv ];
		local $SIG{__WARN__} = sub { die(@_) };
		GetOptionsFromArray(\@argv, \%rawOpts, @specs)
	};
	if ($@)
	{
		pod2usage(-input => $argsPodInput, -message => "Failure parsing options:\n  $@", -exitval => 255, -verbose => 0);
	}

	# simple copies
	#
	$self->{$_} = $rawOpts{$_} foreach (qw(v archive defines timer));

	# help with the hidden flags...
	#
	pod2usage(-input => $_argsPodInput, -exitval => 0, -verbose => 2, -noperldoc => 1) if $rawOpts{_help};

	# for the special selection of running pp, do this first, and it will not return
	#
	$self->__createBinary
				(
					$rawOpts{'_pp-output'},
					$rawOpts{'_pp-force'},
					$rawOpts{v},
					$version,
					$argsPodName, $argsPodInput,
					$manualPodName, $manualPodInput
				) if ($rawOpts{_pp});

	# if any of the doc switches made, display the pod
	#
	pod2usage(-input => $manualPodInput, -exitval => 0, -verbose => 2, -noperldoc => 1) if $rawOpts{manual};
	pod2usage(-input => $argsPodInput, -exitval => 0, -verbose => 2, -noperldoc => 1) if $rawOpts{help};
	pod2usage(-input => $argsPodInput, -exitval => 0, -verbose => 0) if $rawOpts{usage};
	pod2usage(-message => (slashify($0) . " version $version"), -exitval => 0, -verbose => 99, -sections => '_') if $rawOpts{version};

	# use the user skip or include filter for pruning the list of tests later
	#
	eval
	{
		if (defined($rawOpts{skip}) || defined($rawOpts{include}))
		{
			die("The options --skip and --include are mutually exclusive\n") if (defined($rawOpts{skip}) && defined($rawOpts{include}));
			if ($rawOpts{skip})
			{
				# try to compile the query first, to trigger any syntax problem now
				#
				Grep::Query->new($rawOpts{skip});
			
				# since we later want to select *included* files, 
				# we nefariously reverse the expression given
				#
				$self->{include} = Grep::Query->new("NOT ( $rawOpts{skip} )");
			}
			else
			{
				$self->{include} = Grep::Query->new($rawOpts{include});
			}
		}
	};
	if ($@)
	{
		$! = 255;
		die("Failure creating filter:\n  $@");
	}

	# make sure we have a valid jobs value
	#
	pod2usage(-message => "Invalid -jobs value: '$rawOpts{jobs}'", -exitval => 255, -verbose => 0) if $rawOpts{jobs} < 1;
	if ($rawOpts{jobs} < 1)
	{
		$! = 255;
		die("Invalid -jobs value: '$rawOpts{jobs}'\n");
	}
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
			$! = 255;
			die("Failure setting up the save directory:\n  $@");
		}
	}

	# make sure we have the suite root and that it exists as directory
	#
	eval
	{
		die("No suite root provided!\n") unless @argv;
		$self->{suiteroot} = $self->__findSuiteRoot(shift(@argv));
	};
	if ($@)
	{
		$! = 255;
		die("Failure getting suite root directory:\n  $@");
	}

	# we want a config in the suite root
	#
	eval
	{
		$self->{config} = App::TestOnTap::Config->new($self->{suiteroot}, $rawOpts{execmap}); 
	};
	if ($@)
	{
		$! = 255;
		die("Failure handling config in '$self->{suiteroot}':\n  $@");
	}

	# set up the workdir manager
	#
	eval
	{
		$self->{workdirmgr} = App::TestOnTap::WorkDirManager->new($rawOpts{workdirectory}, $self->{suiteroot});
	};
	if ($@)
	{
		$! = 255;
		die("Failure setting up the working directory:\n  $@");
	};

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

sub getFullArgv
{
	my $self = shift;
	
	return $self->{fullargv};
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
	
	return $self->{v};
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

# PRIVATE
#

sub __createBinary
{
	my $self = shift;
	my $output = shift || '.';
	my $force = shift;
	my $verbosity = shift;
	my $version = shift;
	my $argsPodName = shift;
	my $argsPodInput = shift;
	my $manualPodName = shift;
	my $manualPodInput = shift;
	
	die("Sorry, you're already running a binary/packed instance\n") if $IS_PACKED;
	
	eval "require PAR::Packer";
	die("Sorry, it appears PAR::Packer is not installed\n  $@\n") if $@;

	my $os = $IS_WINDOWS ? 'windows' : $^O;
	my $arch = (POSIX::uname())[4]; 
	my $exeSuffix = $IS_WINDOWS ? '.exe' : '';
	if (-d $output)
	{
		$output = slashify(File::Spec->rel2abs("$output/$Script-$version-$os-$arch$exeSuffix"));
	}
	else
	{
		$output = slashify(File::Spec->rel2abs($output));
	}
	
	die("The path '$output' already exists\n") if (!$force && -e $output);
	unlink($output);
	die("Attempt to forcible remove '$output' failed: $!\n") if -e $output;
		
	my @vs = $verbosity > 1 ? ('-' . 'v' x ($verbosity - 1)) : ();
	my @liblocs = map { $_ ne '.' ? ('-I', slashify(File::Spec->rel2abs($_))) : () } @INC;
	my @cmd =
		(
			'pp',
			@vs,
			@liblocs,
			'-a', "$argsPodInput;lib/$argsPodName",
			'-a', "$manualPodInput;lib/$manualPodName",
			'-o', $output,
			slashify("$RealBin/$Script")
		);

	if ($verbosity)
	{
		print "Running:\n";
		print "  $_\n" foreach (@cmd);
	}
	
	my $xit = system(@cmd) >> 8;
	die("Problems creating binary '$output': '$xit'") if ($xit || !-f $output);
	
	print "Created '$output'!\n";
	
	exit(0);
}

sub __findSuiteRoot
{
	my $self = shift;
	my $suiteroot = shift;

	if (-d $suiteroot)
	{
		$suiteroot = slashify(File::Spec->rel2abs($suiteroot));
	}
	else
	{
		die("Not a directory or zip archive: '$suiteroot'\n") unless $suiteroot =~ /\.zip$/i;
		my $zipfile = $suiteroot;
		my $tmpdir = slashify(tempdir("testontap-XXXX", TMPDIR => 1, CLEANUP => 1));

		if (!-f $suiteroot)
		{
			# maybe it's a url?
			# need to dl it before unpacking
			#
			my $localzip = slashify("$tmpdir/local.zip");
			print "Attempting to download '$suiteroot' => $localzip...\n" if $self->{v};
			my $rc = getstore($suiteroot, $localzip);
			die("Treated '$suiteroot' as URL - failed to download : $rc\n") if (is_error($rc) || !-f $localzip);
			$zipfile = $localzip;
		}
		
		print "Attempting to unpack '$zipfile'...\n" if $self->{v};
		my $zip = Archive::Zip->new($zipfile);
		my @memberNames = $zip->memberNames();
		die("The zip archive '$suiteroot' is empty\n") unless @memberNames;
		my @rootEntries = grep(m#^[^/]+/?$#, @memberNames);
		die("The zip archive '$suiteroot' has more than one root entry\n") if scalar(@rootEntries) > 1;
		my $testSuiteDir = $rootEntries[0];
		die("The zip archive '$suiteroot' must have a test suite directory as root entry\n") unless $testSuiteDir =~ m#/$#;
		my $cfgFile = $testSuiteDir . App::TestOnTap::Config::getName();
		die("The zip archive '$suiteroot' must have a '$cfgFile' entry\n") unless grep(/^\Q$cfgFile\E$/, @memberNames);
		die("Failed to extract '$suiteroot': $!\n") unless $zip->extractTree('', $tmpdir) == AZ_OK;
		$suiteroot = slashify(File::Spec->rel2abs("$tmpdir/$testSuiteDir"));
		print "Unpacked '$suiteroot'\n" if $self->{v}; 
	}
	
	return $suiteroot;
}

1;
