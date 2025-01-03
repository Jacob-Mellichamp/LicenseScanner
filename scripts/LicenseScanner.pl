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

Module::LicenseScanner - Gather all CPAN licenses from cpanfile third party dependencies.

=head1 DESCRIPTION

People who redistribute Perl code must be careful that all of the
included libraries are compatible with the final distribution license.
A large fraction of CPAN packages are licensed as C<Artistic/GPL>,
like Perl itself, but not all.  If you are going to package your work
in, say, a PAR archive with all of its dependencies it's critical
that you inspect the licenses of those dependencies.  This module can
help.

This module utilizes CPANM to do much of the hard work of
locating the requested CPAN distribution, downloading and extracting
it.

This distribution is used to gather all dependencies found within a cpanfile. Given an absolute path to a
cpanfile, create a summary of all the distributions listed with their corresponding license. Also, create a directory structure containing all 
the licenses in the form of './licenses/<module name>-<module version>/LICENSE'

This Module Contains both an executable script and perl module function for completing its functional goals. 

=head1 LicenseScanner Script (.pl)

=over 

=item $ perl LicenseScanner.pl `<cpanfile path>`

=back

=head1 LicenseScanner Module (.pm)

=over

=item scan( <cpanfile path> , <verbose_flag>)

Given the Full Path to a cpanfile, extract licensing data from the files listed distribution list. 

=item <cpanfile path> => STRING

Cpanfile Path: A string representation of the absolute path to a CPANFILE

=item <verbose_flag> => BOOLEAN

Verbose Flag: (Optional) Set the 'verbose_flag' parameter to a 'truthy' value for debug output to be produced in the STDERR of the executing process.
              (Default: 0) , truthy values include (1, "1", '1')

=item Examples

```perl
use Module::LicenseScanner qw(scan);
scan("/home/user/project/cpanfile");             # run the scan function on the following filepath with the verbose_flag set to '0'
```

```perl
use Module::LicenseScanner qw(scan);
scan("/home/user/project/cpanfile", 1);          # run the scan function on the following filepath and output debug messages to STDERR
```

```perl
use Module::LicenseScanner qw(scan);
scan("/home/user/project/cpanfile", 1);          # run the scan function on the following filepath and output debug messages to STDERR
```

```perl
use Module::LicenseScanner qw(scan);
scan("C:\\home\\user\\project\\cpanfile", 1);    # run the scan function on the following Windows filepath and output debug messages to STDERR
```

=back

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
