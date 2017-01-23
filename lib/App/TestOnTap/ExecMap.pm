package App::TestOnTap::ExecMap;

use strict;
use warnings;

use App::TestOnTap::Util qw(trim $IS_WINDOWS);

use Config::Std;

# CTOR
#
sub new
{
	my $class = shift;
	my $cfg = shift || __defaultCfg();
	my $delegate = shift;

	my $self = bless( { delegate => $delegate }, $class);
	$self->__parseExecMap($cfg);
	
	return $self;
}

sub newFromFile
{
	my $class = shift;
	my $fn = shift;
	my $delegate = shift;
	
	# read in the file in Config::Std style
	#
	read_config($fn, my %cfg);
	
	my $section = $cfg{EXECMAP};
	die("Missing EXECMAP section in '$fn'\n") unless $section;

	return $class->new($section, $delegate);
}

sub __parseExecMap
{
	my $self = shift;
	my $cfg = shift;

	my %ext2cmd;

	while (my ($exts, $cmdline) = each(%$cfg))
	{
		foreach my $ext (split(' ', trim($exts)))
		{
			# we want to store the cmd as an array
			# Config::Std allows it to be in multiple forms:
			#   a single line (we split it on space)
			#   a ready-made array (take as is)
			#   a string with embedded \n (split on that)
			#
			$ext2cmd{$ext} =
				(ref($cmdline) eq 'ARRAY')
					? $cmdline
					: ($cmdline =~ m#\n#)
						? [ split("\n", $cmdline) ]
						: [ split(' ', $cmdline) ];
		}
	}

	# not much meaning in continuing if there are no mappings at all...!
	#
	die("No entries in the execmap\n") unless keys(%ext2cmd);

	$self->{ext2cmd} = \%ext2cmd;
}

sub __defaultCfg
{
	# TODO: add more useful standard mappings here
	#
	return
		{
			# well, a no-brainer...:-)
			#
			'pl t' => 'perl',
			
			# if python is preferred...
			#
			py => 'python',

			# quite possible and important for java shops
			# (couple with some nice junit and other helpers)
			#
			jar => [qw(java -jar)],
			
			# common variants for groovy scripts, I understand...
			#
			'groovy gsh gvy gy' => 'groovy',
			
			# add other conveniences here
			#
			# 'one or more extensions' => 'command to use',

			# basic platform specifics
			# 
			$IS_WINDOWS
				?
					(
						# possible, but perhaps not likely
						#
						'bat cmd' => [qw(cmd.exe /c)],
					)
				:
					(
						# shell scripting is powerful, so why not
						#
						sh => '/bin/sh'
					),
		}
}

# just check if the given extension is in this map
#
sub mapsExtension
{
	my $self = shift;
	my $ext = shift;

	return
		($ext && exists($self->{ext2cmd}->{$ext}))
			? 1
			: defined($self->{delegate})
				? $self->{delegate}->mapsExtension($ext)
				: 0;
}

# retrieve the command array for the given extension
#
sub getCommandForExtension
{
	my $self = shift;
	my $ext = shift;

	return
		exists($self->{ext2cmd}->{$ext})
			? $self->{ext2cmd}->{$ext}
			: defined($self->{delegate})
				? $self->{delegate}->getCommandForExtension($ext)
				: undef;
}

1;
