#!/usr/bin/env perl

use Modern::Perl;
use IPC::Run qw(harness);
use English '-no_match_vars';

my @new_cmd;

if ($PROGRAM_NAME =~ /\+\+/) {
	push @new_cmd, 'clang++';
} else {
	push @new_cmd, 'clang';
}

for my $arg (@ARGV) {
	if ($arg eq '-lxml2') {
		push @new_cmd, '/usr/local/opt/libxml2/lib/libxml2.a';
		push @new_cmd, '/usr/local/lib/liblzma.a';
		push @new_cmd, qw(-lpthread -lz -liconv -lm);
	} elsif ($arg eq '-lusb-1.0') {
		push @new_cmd, '/usr/local/lib/libusb-1.0.a';
		push @new_cmd, '-lobjc';
		push @new_cmd, '-Wl,-framework,IOKit';
		push @new_cmd, '-Wl,-framework,CoreFoundation';
	} elsif ($arg eq '-lzip') {
		push @new_cmd, '/usr/local/lib/libzip.a';
		push @new_cmd, '-lz';
	} else {
		push @new_cmd, $arg;
	}
}

# make sure we work on old CPUs
push @new_cmd, '-march=core2';

my $h = harness \@new_cmd;
$h->start()->finish();
exit($h->result);
