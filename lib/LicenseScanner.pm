package LicenseScanner;

use strict;
use warnings;
use File::Find;
use File::Copy;
use File::Spec;
use Cwd 'abs_path';
use JSON;
use Exporter 'import';
use File::Path qw(rmtree);

our @EXPORT_OK = qw(initialize_dependency_list print_distributions install_tar_gz);


our $VERSION = 1.0;
our $tmp_dir = 'tmp';
our @tar_files; # list of tar file absolute paths.

################################ Global - Variables #####################################

# Directory where Licenses will be installed
my $directory = "";

my $core_cpanfile    = "";
my $restapi_cpanfile = "";
my %cpanfile_deps;    # from cpanfile reads
my %license_results;
my @errors;

##########################################################################################
sub install_tar_gz {
	clean_up();
	foreach my $dep (keys %cpanfile_deps){
		my $ret = system("cpanm --save-dists $tmp_dir --scandeps $dep");
		if($ret){
			print STDERR "ERROR INSTALLING $ret\n";
			exit 1;
		}
	}
	find( \&find_tar_gz, $directory );
}
# Get all tar.gz files
# Purpose: This file finds All files that end in .tar.gz within the 'lk_com/cpan/windows' directory.
# Output: the @tar_files array contains all the absolute paths of tar files.
sub find_tar_gz {
	if (/\.tar\.gz$/) {    # Match files ending with .tar.gz
		my $absolute_path = abs_path($File::Find::name);
		push @tar_files, $absolute_path;
	}

	if (/\.tgz$/) {        # Match files ending with .tgz
		my $absolute_path = abs_path($File::Find::name);
		push @tar_files, $absolute_path;
	}
}

# Purpose: Reset environment for running the license check.
# Output:  the 'tmp' directory is remade. (this is where modules are untar-ed)
#          the 'lic' directory is made if it has not yet been created.
sub init_license_scan {
	my $ret;
	$ret = system("mkdir $directory\\tmp");
	if ( $ret != 0 ) {
		my $err = $? >> 8;
		if ( $err != 1 ) {
			die "Error $?: failed to make directory $directory\\tmp\n";
		}
	}
	if ( -d "$directory\\license" ) {
		return;
	}
	$ret = system("mkdir $directory\\license");
	if ( $ret != 0 ) {
		my $err = $? >> 8;
		die "Error $err: failed to make directory $directory\\license\n";
	}
}

# Purpose: A Utility Function that is used to read a cpanfile.
# output:  each line of the cpanfile is appended to the global '$cpanfile_deps' hash-map and initialized as "N/A"
sub read_cpan_file {
	my ( $file_path ) = @_;
	print STDERR "[INFO]:\t Reading $file_path cpanfile. . .\n";

	open( my $cpanfile_fh, '<', $file_path )
	  or die "[ERROR]:\t Could not open $file_path CPANFILE\n$!\n";

	# Read the file line by line
	while ( my $cpanfile_line = <$cpanfile_fh> ) {

		# Trim leading/trailing whitespace
		$cpanfile_line =~ s/^\s+|\s+$//g;
		#$cpanfile_line =~ s/::/-/g;

		# Skip comments and empty lines
		next if $cpanfile_line =~ /^#/ || $cpanfile_line eq '';

		if ( $cpanfile_line =~
			/(?:requires|recommends)\s+'([^']+)'\s*,\s*'([^']+)'/ )
		{
			$cpanfile_deps{"$1\@$2"} = "N/A";
		}
		elsif ( $cpanfile_line =~ /(?:requires|recommends)\s+'([^']+)'/ ) {
			$cpanfile_deps{"$1"} = "N/A";
		}
	}
	print STDERR "[INFO]:\t Reading $file_path cpanfile. . . success!\n";
}

# Purpose: Helper function to organize the reading of dependencies
# Output: All necessary cpanfile's have been read and appended to %cpanfile_deps
sub initialize_dependency_list {
	my ($file_path) = @_;
	read_cpan_file($file_path);
}

# Purpose: Given a tarfile and destination directory.
#          Untar a file into the destination directory.
sub unpack_tarfile {
	my ( $tarfile, $dir ) = @_;
	print STDERR "[INFO]:\t untar: $tarfile\n";
	my $cmd = "tar --force-local -xvzf $tarfile -C $dir >nul 2>nul";
	return system($cmd);
}

# Purpose: Given a META.json CPAN metadata file ... search for what license is used.
# In almost all perl distributions, there exists a 'license: []' array that contains
# all the licenses that apply to the distro.
#
# Parameter:
#   - $source_file : META.json absolute_path
#   - $mod : Name of the module that is currently being searched
# Output: For the individual Module '$mod', the license is set on our global %cpanfile_deps Variables
#         or the license is simply not found. This function returns void.
sub license_search {
	my ( $source_file, $mod ) = @_;
	my $fh;
	if ( !open( $fh, '<', $source_file ) ) {
		print STDERR "[ERROR]:\t Failed to open file '$source_file'\n";
		push @errors, "Failed to read $source_file\n";
		close($fh);
		return 1;
	}
	my $file_contents = do { local $/; <$fh> };
	close($fh);

	# decode the 'license' field within the META.json file
	my $data = decode_json($file_contents);
	if ( ref( $data->{license} ) eq 'ARRAY' && @{ $data->{license} } ) {
		my $lic_result = join( ",", @{ $data->{license} } );
		$cpanfile_deps{$mod} = $lic_result;
	}
	else {
		print STDERR "[ERROR]:\t $mod License key not found or empty\n";
		push @errors, "License not found for $mod";
	}
}

sub print_distributions {
	foreach my $distro (keys %cpanfile_deps){
		print STDERR "[INFO]: $distro\n";
	}
}

sub clean_up {

	# Check if the directory exists before attempting to remove it
	if (-d $tmp_dir) {
		rmtree($tmp_dir, { safe => 0 }) or die "Failed to remove directory $tmp_dir: $!";
		print STDERR "[INFO]: Directory $tmp_dir removed successfully.\n";
	} else {
		print STDERR "[ERROR]: Directory $tmp_dir does not exist.\n";
	}
}
1;