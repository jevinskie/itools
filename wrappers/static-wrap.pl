#!/usr/bin/env perl

use Modern::Perl '2023';
use IPC::Run qw(harness);
use English '-no_match_vars';
use Env qw($BROOT);
use File::Find;

my @libdirs;

for my $arg (@ARGV) {
	if ($arg =~ '-L(\S+)') {
		my $libdir = $1;
		say { *STDERR } "libdir: $libdir";
		push @libdirs, $libdir;
	}
}

say { *STDERR } "libdirs: @libdirs";


sub get_static_lib_path {
	my $libname = shift;
	my $static_libname = "lib${libname}.a";
	my $found_path;
	sub wanted {
    	if ($_ eq $static_libname) {
        	$found_path = $File::Find::name;
    	}
	}
	find(\&wanted, @libdirs);
	die "Couldn't find ${static_libname}" unless defined $found_path;
	say { *STDERR } "found  ${static_libname} at ${found_path}";
	return $found_path;
}

# sub get_static_lib_path {
# 	my $libname = shift;
# 	my @pkgconfig_cmd = ("pkg-config", "--libs", "lib${libname}");
# 	my $in = "";
# 	my $out;
# 	my $err;
# 	my $h = harness \@pkgconfig_cmd, \$in, \$out, \$err;
# 	$h->start()->finish();
# 	if ($h->result) {
# 		say { *STDERR } "pkg-config failed: out: ${out} err: ${err}";
# 		exit($h->result);
# 	}

# 	say { *STDERR } "get_static_lib_path pkgconfig_cmd: @pkgconfig_cmd";
# 	say { *STDERR } "get_static_lib_path libname: $libname";
# }

my @new_cmd;

if ($PROGRAM_NAME =~ /\+\+/) {
	push @new_cmd, 'clang++';
} else {
	push @new_cmd, 'clang';
}

for my $arg (@ARGV) {
	if ($arg =~ '-l(\S+)') {
		my $libname = $1;
		say { *STDERR } "libname: $libname";
		my $static_lib_path = get_static_lib_path($libname);
		say { *STDERR } "static_lib_path: $static_lib_path";
		push @new_cmd, $arg;
	} else {
		push @new_cmd, $arg;
	}
}

# make sure we work on old CPUs
# push @new_cmd, '-march=core2';

say { *STDERR } "new_cmd: @new_cmd";
# exit(1);

my $h = harness \@new_cmd;
$h->start()->finish();
exit($h->result);
