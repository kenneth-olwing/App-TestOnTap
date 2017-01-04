package App::TestOnTap::WorkDirManager;

use strict;
use warnings;

use App::TestOnTap::Util qw(slashify stringifyTime $IS_WINDOWS);

use Archive::Zip qw(:ERROR_CODES);
use File::Path;
use File::Basename;
use File::Spec;
use File::Copy::Recursive qw(dircopy);
use File::Temp qw(tempdir);
use File::Slurp qw(write_file);
use JSON;
use Net::Domain qw(hostfqdn);
use POSIX qw(uname);

# CTOR
#
sub new
{
	my $class = shift;
	my $workdir = shift;
	my $suiteRoot = shift;
	
	if ($workdir)
	{
		# if user specifies a workdir this implies that it should be kept
		# just make sure there is no such directory beforehand, and create it here
		# (similar to below; tempdir() will also create one)
		#
		$workdir = slashify(File::Spec->rel2abs($workdir));
		die("The workdir '$workdir' already exists\n") if -e $workdir;
		mkpath($workdir) or die("Failed to create workdir '$workdir': $!\n");
	}
	else
	{
		# create a temp dir; use automatic cleanup
		#
		$workdir = slashify(tempdir("testontap-workdir-XXXX", TMPDIR => 1, CLEANUP => 1));
	}

	my $self = bless
				(
					{
						suiteroot => $suiteRoot,
						root => $workdir,
						tmp => slashify("$workdir/tmp"),
						private => slashify("$workdir/data/private"),
						tap =>  slashify("$workdir/data/tap"),
						result =>  slashify("$workdir/data/result"),
						json => JSON->new()->utf8()->pretty()->canonical() 
					},
					$class
				);

	foreach my $p (qw(tmp private tap result))
	{
		mkpath($self->{$p}) || die("Failed to mkdir '$self->{$p}': $!\n");
	}

	return $self;
}

sub beginTestRun
{
	my $self = shift;
	
	$self->{begin} = time();
	
	$self->__save("$self->{root}/data/env", { %ENV });
}

sub endTestRun
{
	my $self = shift;
	my $args = shift;
	my $aggregator = shift;
	
	$self->{end} = time();
	$self->{runid} = $args->getId();

	my $summary =
		{
			all_passed => $aggregator->all_passed() ? 1 : 0,
			status => $aggregator->get_status(),
			failed => [ $aggregator->failed() ],
			parse_errors => [ $aggregator->parse_errors() ],
			passed => [ $aggregator->passed() ],
			planned => [ $aggregator->planned() ],
			skipped => [ $aggregator->skipped() ],
			todo => [ $aggregator->todo() ],
			todo_passed => [ $aggregator->todo_passed() ],
		};
	$self->__save("$self->{root}/data/summary", $summary);
	
	my $elapsed = $aggregator->elapsed();
	my $meta =
		{
			format => { major => -1, minor => 0 }, # Change when format of result tree is changed in any way.
			runid => $args->getId(),
			suiteid => $args->getConfig()->getId(),
			suitename => basename($args->getSuiteRoot()),
			begin => stringifyTime($self->{begin}),
			end => stringifyTime($self->{end}),
			elapsed =>
				{
					str => $aggregator->elapsed_timestr(),
					real => $elapsed->real(),
					cpu => $elapsed->cpu_a(),
				},
			user => $IS_WINDOWS ? getlogin() : scalar(getpwuid($<)),
			host => hostfqdn(),
			jobs => $args->getJobs(),
			argv => $args->getArgv(),
			defines => $args->getDefines(),
			platform => $^O,
			uname => [ uname() ]
		};
	$self->__save("$self->{root}/data/meta", $meta);
}

sub openTAPHandle
{
	my $self = shift;
	my $testPath = slashify(shift, '/');
	
	my $sr = slashify($self->{suiteroot}, '/');
	$testPath =~ s#^\Q$sr\E/(.*)#$1#;
	my $tapPath = slashify("$self->{tap}/$testPath.tap");
	mkpath(dirname($tapPath));
	open(my $h, '>', $tapPath) or die("Failed to open '$tapPath': $!");
	
	return $h;
}

sub closeTAPHandle
{
	my $self = shift;
	my $parser = shift;
	
	my $spool_handle = $parser->delete_spool;
	close($spool_handle) if $spool_handle;
	
	return;
}

sub getResultCollector
{
	my $self = shift;
	
	return
		sub
			{
				my $pathAndNamePair = shift;
				my $parser = shift;

				my %results =
					(
						# individual test results
						#
						passed => [ $parser->passed() ],
						actual_passed => [ $parser->actual_passed() ],
						failed => [ $parser->failed() ],
						actual_failed => [ $parser->actual_failed() ],
						todo => [ $parser->todo() ],
						todo_passed => [ $parser->failed() ],
						skipped => [ $parser->skipped() ],
						
						# total test results
						#
						has_problems => $parser->has_problems() ? 1 : 0,
						plan => $parser->plan(),
						is_good_plan => $parser->is_good_plan() ? 1 : 0,
						tests_planned => $parser->tests_planned(),
						tests_run => $parser->tests_run(),
						skip_all => ($parser->skip_all() ? $parser->skip_all() : 0),
						start_time => stringifyTime($parser->start_time()),
						end_time => stringifyTime($parser->end_time()),
						version => $parser->version(),
						'exit' => $parser->exit(),
						parse_errors => [ $parser->parse_errors() ],
					);
	
				$self->__save("$self->{result}/$pathAndNamePair->[1]", \%results);
			};
}

sub saveResult
{
	my $self = shift;
	my $resultDir = shift;
	my $asArchive = shift;

	my $pfx = basename($self->{suiteroot});
	my $runid = $self->{runid};
	my $ts = stringifyTime($self->{begin});
	my $name = "$pfx.$ts.$runid";
	my $from = slashify("$self->{root}/data");

	my $to;
	if ($asArchive)
	{
		$to = slashify("$resultDir/$name.zip");
		my $zip = Archive::Zip->new();
		$zip->addTree($from, $name);
		my $err = $zip->writeToFileNamed($to);
		die("Failed to write archive '$to': $!\n") if $err != AZ_OK;
	}
	else
	{
		$to = slashify("$resultDir/$name");
		{
			local $File::Copy::Recursive::KeepMode = 0;
			die("Failed to copy result '$from' => '$to': $!\n") unless dircopy($from, $to);
		} 
	}
	
	return $to;
}

sub getTmp
{
	my $self = shift;
	
	return $self->{tmp};
}

sub getPrivate
{
	my $self = shift;
	
	return $self->{private};
}

sub __save
{
	my $self = shift;
	my $name = shift;
	my $data = shift;
	
	my $file = slashify("$name.json");
	mkpath(dirname($file));
	write_file($file, $self->{json}->encode($data)) || die("Failed to write '$file': $!\n");
}

1;
