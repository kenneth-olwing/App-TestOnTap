package App::TestOnTap::Harness;

use strict;
use warnings;

use base qw(TAP::Harness);

use App::TestOnTap::Scheduler;
use App::TestOnTap::Dispenser;
use App::TestOnTap::Util qw(getExtension slashify $IS_PACKED);

use TAP::Formatter::Console;
use TAP::Formatter::File;

sub new
{
	my $class = shift;
	my $args = shift;

	my $self = $class->SUPER::new
								(
									{
										formatter => __getFormatter($args),
										jobs => $args->getJobs(),
										callbacks => { after_test => $args->getWorkDirManager()->getResultCollector() },
										'exec' => __getExecMapper($args),
										scheduler_class => 'App::TestOnTap::Scheduler'
									}
								);

	$self->{testontap} = { args => $args, pez => App::TestOnTap::Dispenser->new($args) };

	return $self;
}

sub make_scheduler
{
	my $self = shift;
	
	return $self->{scheduler_class}->new($self->{testontap}->{pez}, @_);
}

sub runtests
{
	my $self = shift;
	
	my $sr = $self->{testontap}->{args}->getSuiteRoot();
	
	my @pairs;
	push(@pairs, [ slashify("$sr/$_"), $_ ]) foreach ($self->{testontap}->{pez}->getAllTests());

	my $aggregator;
	{
		my $wdmgr = $self->{testontap}->{args}->getWorkDirManager();

		my %e = %ENV;		 
		local %ENV = %e;
		$ENV{TESTONTAP_SUITE_DIR} = $sr;
		$ENV{TESTONTAP_TMP_DIR} = $wdmgr->getTmp();
		$ENV{TESTONTAP_PRIVATE_DIR} = $wdmgr->getPrivate();
		
		# as a very special workaround - when running as a packed binary, any PERL5LIB envvar
		# is cleared, but if it's really needed, any TESTONTAP_PERL5LIB will be used to reinsert
		# it here for our children
		# 
		$ENV{PERL5LIB} = $ENV{TESTONTAP_PERL5LIB} if ($IS_PACKED && $ENV{TESTONTAP_PERL5LIB});
		
		$wdmgr->beginTestRun();
		$aggregator = $self->SUPER::runtests(@pairs); 
		$wdmgr->endTestRun($self->{testontap}->{args}, $aggregator);
		
		# drop the special workaround envvar...
		#
		delete $ENV{PERL5LIB} if $IS_PACKED;
	}
	
	my $failed = $aggregator->failed() || 0;
	return ($failed > 127) ? 127 : $failed;
}

sub _open_spool
{
	my $self = shift;
	my $testpath = shift;

	return $self->{testontap}->{args}->getWorkDirManager()->openTAPHandle($testpath);
}

sub _close_spool
{
    my $self = shift;
    my $parser = shift;;

	$self->{testontap}->{args}->getWorkDirManager()->closeTAPHandle($parser);

	return; 
}

sub __getExecMapper
{
	my $args = shift;

	return sub
			{
				my $harness = shift;
				my $testfile = shift;
		
				my $cmd = $args->getConfig()->getCommandForExtension(getExtension($testfile));
				my $argv = $args->getArgv();
				
				my $cmdline = [ @$cmd, $testfile, @$argv ];
				
				# trim down the full file name to the test name
				#
				my $srfs = slashify($args->getSuiteRoot(), '/');
				my $testname = slashify($testfile, '/');
				$testname =~ s#^\Q$srfs\E/##;
				$args->getWorkDirManager()->recordCommandLine($testname, $cmdline);
				
				return $cmdline;
			};
}

sub __getFormatter
{
	my $args = shift;

	my $formatterArgs = 
						{
							jobs => $args->getJobs(),
							timer => $args->getTimer(),
							show_count => 1,
							verbosity => $args->getVerbose(),
						};
						
	return
		-t \*STDOUT
			?	TAP::Formatter::Console->new($formatterArgs)
			:	TAP::Formatter::File->new($formatterArgs);
}

1;
