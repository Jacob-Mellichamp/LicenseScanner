#!perl

# Test should be ran at the root of the module.

use strict;
use warnings;
use Test::More tests => 8;
use File::Temp;
use lib "./lib";
use Module::LicenseScanner qw(read_cpan_file format_cpanfile_entries);
use Cwd qw (abs_path getcwd);

$Module::LicenseScanner::verbose_flag = 1;
my $mockedFile = getcwd() . "/t/mocked_cpanfile";

# Testing read_cpanfile_function
read_cpan_file($mockedFile);

is(scalar %Module::LicenseScanner::cpanfile_deps, 3, "Found 3 Stubbed Modules in cpanfile");
is($Module::LicenseScanner::cpanfile_deps{'List::Util@1.68'}, "N/A", "Found Test Module: List::Util");
is($Module::LicenseScanner::cpanfile_deps{'Test::Harness@3.50'}, "N/A", "Found Test Module: Test::Harness");
is($Module::LicenseScanner::cpanfile_deps{'Test::More@0.05'}, "N/A", "Found Test Module: Test::More");


# Testing format_cpanfile_entries
format_cpanfile_entries();
is(scalar %Module::LicenseScanner::cpanfile_formatted, 3, "Formatted 3 Stubbed Modules in cpanfile");
is($Module::LicenseScanner::cpanfile_formatted{'List-Util-1.68'}, "N/A", "Formatted Test Module: List::Util");
is($Module::LicenseScanner::cpanfile_formatted{'Test-Harness-3.50'}, "N/A", "Formatted Test Module: Test::Harness");
is($Module::LicenseScanner::cpanfile_formatted{'Test-More-0.05'}, "N/A", "Formatted Test Module: Test::More");


for my $key (keys %Module::LicenseScanner::cpanfile_deps){
	print "Key Found: $key\n";
}
done_testing();
