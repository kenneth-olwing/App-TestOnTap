package App::TestOnTap::Preprocess;

use strict;
use warnings;

our $VERSION = '0.059';
my $version = $VERSION;
$VERSION = eval $VERSION;

use POSIX;
use App::TestOnTap::Util qw(runprocess);

# CTOR
#
sub new
{
	my $class = shift;
	my $cmd = shift;
	my $args = shift;
	my $env = shift;
	my $argv = shift;

	my $self = bless( { env => $env, argv => $argv }, $class);
	$self->__execPreprocess($cmd, $args) if ($cmd && @$cmd);
	
	return $self;
}

sub getEnv
{
	my $self = shift;
	
	return $self->{env};
}

sub getArgv
{
	my $self = shift;

	return $self->{argv};
}

sub __execPreprocess
{
	my $self = shift;
	my $cmd = shift;
	my $args = shift;

	my @preproc;	
	my $xit = runprocess
				(
					sub
						{
							my $l = shift;
							chomp($l);
							$l =~ s/^\s+|\s+$//g;
							push(@preproc, $l) if $l;
						},
					$args->getSuiteRoot(),
					(
						@$cmd,
						@{$self->getArgv()}
					)
				);	 
	
	die("ERROR: exit code '$xit' when running preprocess command\n") if $xit;

	$args->getWorkDirManager()->recordPreprocess([ @preproc ]);

	my %types =
		(
			ENV => sub { $self->__parseEnvLines(@_) },
			ARGV => sub { $self->__parseArgvLines(@_) }
		);

	while (my $line = shift(@preproc))
	{
		if ($line =~ /^\s*#\s*BEGIN\s+([^\s]+)\s*$/ && exists($types{$1}))
		{
			$types{$1}->($1, \@preproc);
		}
		else
		{
			warn("WARNING: Unexpected line during preprocessing: '$line'\n");
		}
	}
}

sub __parseEnvLines
{
	my $self = shift;
	my $type = shift;
	my $preproc = shift;

	my %env;
	while (my $line = shift(@$preproc))
	{
		last if $line =~ /^\s*#\s*END\s+\Q$type\E\s*$/;
		die("Invalid $type line during preprocessing: '$line'\n") unless ($line =~ /^([^=]+)=(.*)/);
		$env{$1} = $2 || '';
	}
	
	$self->{env} = \%env;
}

sub __parseArgvLines
{
	my $self = shift;
	my $type = shift;
	my $preproc = shift;

	my @argv;
	while (my $line = shift(@$preproc))
	{
		last if $line =~ /^\s*#\s*END\s+\Q$type\E\s*$/;
		push(@argv, $line);
	}
	
	$self->{argv} = \@argv;
}

1;
