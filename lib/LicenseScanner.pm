package LicenseScanner;

use strict;
use warnings;
use File::Copy;
use File::Find;
use File::Spec;
use File::Path qw(rmtree);
use File::Which;
use Cwd qw (abs_path getcwd);
use JSON;
use Exporter 'import';
our @EXPORT_OK = qw(scan);



################################ Global - Variables #####################################
our $VERSION = 1.0;
our $directory = getcwd();
our $tmp_dir = "$directory/tmp";
our $lic_dir = "$directory/licenses";
our @tar_files; # list of tar file absolute paths.
our %cpanfile_deps;    # from cpanfile reads formatted Test::Harness@0.05
our %cpanfile_formatted; # formatted Test-Harness-0.05
our %license_results;
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
	find( \&find_tar_gz, $tmp_dir );
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
	format_cpanfile_entries(); 
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
	my $cmd = "tar -xvzf $tarfile -C $dir >nul 2>nul";
	print STDERR "$cmd\n";
	return system($cmd);
}

sub format_cpanfile_entries {
	foreach my $distro (keys %cpanfile_deps){
		my $tmp = $distro;
		$tmp =~ s/::/-/g;   # Replace "::" with "-"
		$tmp =~ s/@/-/;     # Replace "@" with "-"
		$cpanfile_formatted{$tmp} = "N/A";
	}
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
		$cpanfile_formatted{$mod} = $lic_result;
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

sub extract_readme {
	my ($file, $dest) = @_;
	open(my $fh, '<', $file) or die "Could not open file '$file': $!"; # Open the README file

	my $extracting = 0;
	my @section;

	while (my $line = <$fh>) {
		chomp $line;

		# Detect the start of the "Copyright & License" section
		if ($line =~ /^(Copyright|COPYRIGHT|copyright|LICENSE)/i) {
			$extracting = 1;
			push @section, $line;
			next;
		}

		# Detect the end of the section (e.g., blank line or next heading)
		if ($extracting && $line =~ /^\s*$/) {
			$extracting = 0;
			next;
		}

		# Add lines to the section if within the desired block
		push @section, $line if $extracting;
	}

	close $fh;

	if (@section) {
		open(my $dest_fh, ">", $dest) || die "[ERROR]: could not write to LICENSE FILE $dest\n";
		print $dest_fh join("\n", @section);
		close($dest_fh);
	} else {
		push @errors, "[WARN]: No 'Copyright & License' section found for file: $file.\n";
	}

	

}

sub check_for_tar {
	my $command = 'tar';

	if (which($command)) {
		return 0;
	} else {
		push @errors, "[ERROR]:\t Command 'tar', not found in path.\n";
		return 1;
	}
}
sub search_all {
	# if not a directory already. . .
	if ( !-d $lic_dir ) {
		if(mkdir $lic_dir){
			print "Directory '$lic_dir' created successfully.\n";
		} else {
			die "Failed to create directory '$lic_dir': $!\n";
		}
	}

	foreach my $tarfile (@tar_files) {
		if ( $tarfile =~ m{([^/\\]+)(?=\.tar\.gz$)} ) {
			my $module = $1;

			# if tarfile is not in our cpanfile_deps don't get the license.
			if ( !exists $cpanfile_formatted{$module} ) {
				next;
			}

			# check if we've scanned the module already.
			if ( $cpanfile_formatted{$module} ne "N/A" ) {
				next;
			}

			# unpack the tarfile
			my $ret = unpack_tarfile( $tarfile, "$directory/tmp/" );
			if ( $ret != 0 ) {
				print STDERR "[ERROR]:\t Unpacking $tarfile\n";
				push @errors, "$tarfile was not scanned. . . manual entry required";
				next;
			}
			# Find unpacked directory and setup license Directory
			my $module_path = $tmp_dir . "/$module";
			my $dest_dir    = $lic_dir . "/$module";

			opendir( my $dh, $module_path ) or push @errors, "[ERROR]:\t Cannot open directory: $module_path\n $!" and next;

			# Open the directory for writing
			while ( my $file = readdir($dh) ) {
				next if $file =~ /^\./;    # Skip . and .. entries
				next
				unless $file =~ /^(LICENSE|COPYING|README|META.JSON|META.YML)$/i;

				if ( $file =~ /^META.JSON$/i ) {
					# Read the META.JSON File... find the license type
					license_search( "$module_path/$file", $module );
				}

				if ( $file =~ /^(LICENSE|COPYING)$/i ) {
					# Construct full paths for source and destination
					my $source_file = File::Spec->catfile( $module_path, $file );
					my $dest_file = File::Spec->catfile( "$dest_dir", "LICENSE");

					# Copy and rename the file
					if ( !copy( $source_file, $dest_file ) ) {
						print STDERR "Failed to copy '$source_file' to '$dest_file': $!";
						push @errors,"Failed to copy '$source_file' to '$dest_file': $!";
					}

				}

				if ( $file=~ /^(README|README.MD)$/i ) {

					if(mkdir "$dest_dir"){
						print STDERR "[INFO]: Directory '$dest_dir' created successfully.\n";
					} else {
						push @errors, "Failed to create directory '$dest_dir': $!\n";
					}
					extract_readme("$module_path/$file", "$dest_dir/LICENSE");
				}
				close($dh);
			}
		}
	}

	clean_up(); # clean up tmp folders and contents.
	open( my $report, ">", "$lic_dir/license-report.txt" );
	foreach my $key ( sort keys %cpanfile_formatted ) {
		print $report " - Module: $key\tlicense:\t" . $cpanfile_formatted{$key} . "\n";
	}
	close($report);

}

sub print_errors {
	# Print out any errors that took place
	foreach my $err (@errors) {
		print STDERR "[ERROR]:\t $err\n";
	}
}
sub scan {
	my ($cpanfile) = @_;
	my $err = check_for_tar();
	if($err){
		print_errors();
		die 1;
	}
	initialize_dependency_list($cpanfile);
	print_distributions();
	install_tar_gz();
	search_all();
	print_errors();
}

1;