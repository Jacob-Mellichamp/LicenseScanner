#!perl
use strict;
use warnings;
use lib "../lib"
use Module::LicenseScanner qw(scan);

##################################### Pre - Checks #####################################

# Check for the presence of a cpanfile commandline argument.
my $cpanfile_path;
if(!$ARGV[0]){
	print "Usage: perl LicenseScanner.pl <cpanfile path>\n";
	exit 1;
}
$cpanfile_path = $ARGV[0];

print STDERR "[INFO]: Cpanfile Location: $cpanfile_path\n";

################################ MAIN ######################################################

scan($cpanfile_path);

__END__

=head1 NAME

licenseScan.pl - This file is used to gather all CPAN licenses from third party dependencies.

=head1 DESCRIPTION

This file is used to gather all dependencies found within a cpanfile. Given an absolute path to a
cpanfile, create a summary of all the distributions listed with their corresponding license. Also, create a directory structure containing all 
the licenses in the form of './licenses/<module name>-<module version>/LICENSE'

=head1 PERL CMDLINE EXAMPLE

$ perl LicenseScanner.pl `<cpanfile path>`


=head1 PERL MODULE EXAMPLE:
```perl

use Module::LicenseScanner qw(scan);

scan("root/path/to/cpanfile");

```

=head1 AUTHOR

Jake Mellichamp

=head1 LICENSE

GNU v3, Perl_5 license

=head1 INSTALLATION

Using C<cpanm>:

    $ cpanm LicenseScanner

Manual install:

    $ perl Makefile.PL
    $ make
    $ make install

=cut
