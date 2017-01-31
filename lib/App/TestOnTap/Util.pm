package App::TestOnTap::Util;

use strict;
use warnings;

use POSIX qw(strftime);
use File::Basename;

our $IS_WINDOWS = $^O eq 'MSWin32';
our $IS_PACKED = $ENV{PAR_0} ? 1 : 0;

use Exporter qw(import);
our @EXPORT_OK =
	qw
		(
			slashify
			trim
			getExtension
			stringifyTime
			expandAts
			$IS_WINDOWS
			$IS_PACKED
		);

my $file_sep = $IS_WINDOWS ? '\\' : '/';

# pass in a path and ensure it contains the native form of slash vs backslash
# (or force either one)
#
sub slashify
{
	my $s = shift;
	my $fsep = shift || $file_sep;

	my $dblStart = $s =~ s#^[\\/]{2}##;
	$s =~ s#[/\\]+#$fsep#g;

	return $dblStart ? "$fsep$fsep$s" : $s;
}

# trim off any ws at front/end of a string
#
sub trim
{
	my $s = shift;

	$s =~ s/^\s+|\s+$//g if defined($s);

	return $s;
}

sub getExtension
{
	my $p = shift;
	
	my $bn = basename($p);

	my $lastPer = rindex($bn, '.');
	return if $lastPer == -1;

	return substr($bn, $lastPer + 1); 
}

# turn an epoch time into a compact ISO8601 UTC string
#
sub stringifyTime
{
	my $tm = shift;
	
	# deal with possible hires timings and
	# convert the raw timestamps to strings
	#
	my $subsecs = '';
	if ($tm =~ m#\.#)
	{
		$tm =~ s#^([^\.]+)\.(.*)#$1#;
		$subsecs = ".$2";
	}
	
	return strftime("%Y%m%dT%H%M%S${subsecs}Z", gmtime($tm));
}

sub expandAts
{
	my $dirctx = shift;
	
	my @a;
	foreach my $e (@_)
	{
		if ($e =~ /^@(.+)/)
		{
			my @fa = expandAts(__readLines($1));
			@fa = ($e) unless @fa;
			push(@a, @fa)
		}
		else
		{
			push(@a, $e);
		}
	}
	return @a;
}

sub __readLines
{
	my $fn = shift;
	
	my @lines;
	if (-f $fn)
	{
		open (my $fh, '<', $fn) or die("Failed to open '$fn': $!\n");
		my $line;
		while (defined($line = <$fh>))
		{
			chomp($line);
			if ($line =~ s#\\\s*$##)
			{
				$line .= <$fh>;
				redo unless eof($fh);
			}
			push(@lines, $line);
		}
		close($fh);
	}
	
	return @lines;
}

1;
