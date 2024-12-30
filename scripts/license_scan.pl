#!perl

=head1 NAME

licenseScan.pl - This file is used to gather all CPAN licenses from third party dependencies.

=head1 DESCRIPTION

This file is used to gather all dependencies found within a cpanfile. Given an absolute path to a
cpanfile, create a summary of all the licenses within the file. Also, a directory structure containing all 
the licenses in the form of './licenses/<module name>-<module version>/LICENSE'

=head1 SYNOPSIS

  $ perl licenseScanner.pl -f <cpanfile>

=head1 AUTHOR

Jake Mellichamp

=head1 LICENSE

GNU, perl5 license

=head1 INSTALLATION

Using C<cpan>:

    $ cpan LicenseScanner

Manual install:

    $ perl Makefile.PL
    $ make
    $ make install

=cut

use strict;
use warnings;
use lib "../lib/";
use LicenseScanner qw(initialize_dependency_list print_distributions install_tar_gz);

##################################### Pre - Checks #####################################

# Check for the presence of a cpanfile commandline argument.
my $cpanfile_path;
if(!$ARGV[0]){
	print "Usage: perl LicenseScanner.pl <cpanfile path>\n";
	exit 1;
}
$cpanfile_path = $ARGV[0];
print "cpanfile $cpanfile_path\n";


################################ Global - Variables #####################################

# Directory where Licenses will be installed
my $directory = "";
my @tar_files;    # list of tar file absolute paths.

my $core_cpanfile    = "";
my $restapi_cpanfile = "";
my %cpanfile_deps;    # from cpanfile reads
my %license_results;
my @errors;

################################ MAIN ######################################################

initialize_dependency_list($cpanfile_path);
print_distributions();
install_tar_gz();


# install the perl distro into a tmp directory. 

# Recursively search the directory
#find( \&find_tar_gz, $directory );

# ### initialize environment for license scanning.
# initialize_dependency_list();

# init_license_scan();

# print STDERR "[INFO]\t: " . $_ . "\n" for keys %cpanfile_deps;
# print STDERR "[INFO]:\t "
#   . ( scalar(@tar_files) )
#   . " amount of files to go through\n";

# foreach my $tarfile (@tar_files) {
# 	if ( $tarfile =~ m{([^/\\]+)(?=\.tar\.gz$)} ) {
# 		my $module = $1;

# 		# if tarfile is not in our cpanfile_deps don't get the license.
# 		if ( !exists $cpanfile_deps{$module} ) {
# 			next;
# 		}

# 		# check if we've scanned the module already.
# 		if ( $cpanfile_deps{$module} ne "N/A" ) {
# 			next;
# 		}

# 		# unpack the tarfile
# 		my $ret = unpack_tarfile( $tarfile, "$directory/tmp/" );
# 		if ( $ret != 0 ) {
# 			print STDERR "[ERROR]:\t Unpacking $tarfile\n";
# 			push @errors, "$tarfile was not scanned. . . manual entry required";
# 			next;
# 		}

# 		# Find unpacked directory and setup license Directory
# 		my $module_path = $directory . "\\tmp\\$module";
# 		my $dest_dir    = $directory . "\\license\\$module";

# 		# if not a directory already. . .
# 		if ( !-d $dest_dir ) {
# 			$ret = system("mkdir $dest_dir");
# 			if ( $ret != 0 ) {
# 				print STDERR "Error failed to make directory $dest_dir\n";
# 				push @errors,
# 				  "[ERROR]\t Error failed to make directory $dest_dir -- $!\n";
# 			}
# 		}

# 		opendir( my $dh, $module_path )
# 		  or print STDERR "[ERROR]:\t Cannot open directory: $module_path\n $!"
# 		  and next;

# 		# Open the directory for writing
# 		while ( my $file = readdir($dh) ) {
# 			next if $file =~ /^\./;    # Skip . and .. entries
# 			next
# 			  unless $file =~ /^(LICENSE|COPYING|README|META.JSON|META.YML)$/i;

# 			if ( $file =~ /^META.JSON$/i ) {

# 				# Read the META.JSON File... find the license type
# 				license_search( "$module_path\\$file", $module );
# 			}

# 			if ( $file =~ /^(LICENSE|COPYING)$/i ) {

# 				# Construct full paths for source and destination
# 				my $source_file = File::Spec->catfile( $module_path, $file );
# 				my $dest_file =
# 				  File::Spec->catfile( "$dest_dir", "$module-$file" );

# 				# Copy and rename the file
# 				if ( !copy( $source_file, $dest_file ) ) {
# 					print STDERR
# 					  "Failed to copy '$source_file' to '$dest_file': $!";
# 					push @errors,
# 					  "Failed to copy '$source_file' to '$dest_file': $!";
# 				}

# 			}
# 			close($dh);
# 		}
# 	}
# }
# my $ret = system("rm -rf $directory\\tmp");
# if ( $ret != 0 ) {
# 	push @errors, "Could not remove the $directory\\tmp";
# }
# open( my $report, "+>>", "$directory\\license\\report-dev.md" );

# foreach my $key ( sort keys %cpanfile_deps ) {
# 	print $report " - Module: $key\tlicense:\t" . $cpanfile_deps{$key} . "\n";
# }
# close($report);

# # Print out any errors that took place
# foreach my $err (@errors) {
# 	print STDERR "[ERROR]:\t $err\n";
# }

