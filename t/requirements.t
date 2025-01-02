#!perl

# Test should be ran at the root of the module.

use strict;
use warnings;
use Test::More tests => 2;

# List of executables required
my @executables = ("tar", "cpanm");

# Get the Operating System Name
my $check_command = $^O eq 'MSWin32' ? 'where' : 'which';

# Function to check if an executable is callable
sub is_executable_callable {
	my ($exe) = @_;
	my $path = `$check_command $exe`;  # Use 'where' instead of 'which' on Windows
	chomp $path;
	return $path;
}

foreach my $exe (@executables) {
	 ok(is_executable_callable($exe), "'$exe' is callable");
}

done_testing();
