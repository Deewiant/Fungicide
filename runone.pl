#!/usr/bin/perl

use warnings;
use strict;

use BSD::Resource qw(setrlimit RLIMIT_CPU);
use File::Compare qw(compare);
use File::Path    qw(make_path remove_tree);
use POSIX         qw(mkfifo WIFSIGNALED :sys_wait_h);
use Time::HiRes   qw(gettimeofday tv_interval usleep);

my $MEM_RUNS       = 1;
my $CPU_RUNS_1m    = 10;
my $CPU_RUNS_10m   = 3;
my $CPU_RUNS_other = 1;

if ($#ARGV+1 < 3) {
	print STDERR "Usage: $0 <dir to write to> <program to run> <interpreter to use> [interpreter args...]\n";
	print STDERR "\n";
	print STDERR "Expects <program>.expected to exist, with the expected stdout.\n";
	exit 2;
}

my $tmpdir = shift @ARGV;
my $prog   = shift @ARGV;
my $interp = join ' ', @ARGV;

my $cmd = "$interp $prog";

make_path $tmpdir;
my $output     = "$tmpdir/out";
my $errput     = "$tmpdir/err";
my $timeput    = "$tmpdir/time";
my $memput     = "$tmpdir/mem";
my $memtimeput = "$tmpdir/memtime";
my $pid_in     = "$tmpdir/pid_in";

my $TIMEOUT = 10800; # 3 hours

mkfifo($pid_in, 0644);

system("sudo python -O onepid_mem.py $pid_in | gzip -9 -c >$memput 2>/dev/null &");

open(my $pid_in_h, "> $pid_in") or die $!;
open(my $memtimeput_h, "> $memtimeput") or die $!;

my $diff;
for (my $i = 0; $i < $MEM_RUNS; ++$i) {
	print $pid_in_h "d\n" if ($i > 0);

	my $t0 = [gettimeofday];

	my $pid = fork; defined $pid or die $!;
	if (!$pid) {
		open STDOUT, ">$output";
		open STDERR, ">$errput";
		setrlimit(RLIMIT_CPU, $TIMEOUT, $TIMEOUT);
		exec $cmd;
	}
	do { print $pid_in_h "$pid\n" } while (waitpid($pid, WNOHANG) >= 0);

	$diff = tv_interval($t0);

	if (WIFSIGNALED($?)) {
		print $memtimeput_h "CRASH $diff\n";
		print 'C ';
		print $pid_in_h "q\n";
		close $pid_in_h;
		unlink $pid_in;
		close $memtimeput_h;
		exit 0
	}

	if ($diff >= $TIMEOUT) {
		print $memtimeput_h "TIMEOUT $diff\n";
		print 'T ';
		print $pid_in_h "q\n";
		close $pid_in_h;
		unlink $pid_in;
		close $memtimeput_h;
		exit 0
	}

	++$|;
	print 'm';
	--$|;
	print $memtimeput_h "$diff\n";

	my $ok = ! -s $errput;
	if ($ok) {
		open(my $output_h, "< $output") or $ok = 0;
		if ($ok) {
			my $line = <$output_h>;
			$ok = !$! && $line eq "15 ";
		}
	}

	if (!$ok) {
		print STDERR "Error: output did not match expected\n";
		print STDERR "Got: "; system("cat $output >&2 2>/dev/null");
		print STDERR "\nAnd some errors" if -e "$errput";
		print STDERR "\n";
		print $pid_in_h "q\n";
		close $pid_in_h;
		print ' ';
		remove_tree($tmpdir);
		close $memtimeput_h;
		exit 1
	}
}
print $pid_in_h "q\n";
close $pid_in_h;
unlink $pid_in;

close $memtimeput_h;

my $CPU_RUNS;
if ($diff > 10*60) {
	$CPU_RUNS = $CPU_RUNS_other;
} elsif ($diff > 60) {
	$CPU_RUNS = $CPU_RUNS_10m;
} else {
	$CPU_RUNS = $CPU_RUNS_1m;

	system "$cmd >/dev/null 2>&1";
	print 'p';
}

open(my $timeput_h, "> $timeput") or die $!;

for (my $i = 0; $i < $CPU_RUNS; ++$i) {
	my $t0 = [gettimeofday];

	my $pid = fork; defined $pid or die $!;
	if (!$pid) {
		open STDOUT, ">$output";
		open STDERR, ">$errput";
		exec $cmd;
	}
	wait;
	my $diff = tv_interval($t0);

	++$|;
	print 'c';
	--$|;
	print $timeput_h "$diff\n";

	my $ok = ! -s $errput;
	if ($ok) {
		open(my $output_h, "< $output") or $ok = 0;
		if ($ok) {
			my $line = <$output_h>;
			$ok = !$! && $line eq "15 ";
		}
	}

	if (!$ok) {
		print STDERR "Error: output did not match expected\n";
		print STDERR "Got: "; system("cat $output >&2 2>/dev/null");
		print STDERR "\nAnd some errors" if -e "$errput";
		print STDERR "\n";
		print ' ';
		remove_tree($tmpdir);
		exit 1
	}
}
print ' ';
