#! /usr/bin/perl

# ============================================================================
# $RCSfile$
# $Source$
# $Revision$
# $Date$
# $Author$
# $Name$
#
# DESCRIPTION:
# ============================================================================

# PRAGMAS
use strict;
use warnings;

# MODULES
use Getopt::Long;
use File::Spec;
use Data::Dumper;
use Readonly;
use Net::FTP;

# LIBRARIES

# ----------------------------------------------------------------------------

# Data::Dumper configuration
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Indent   = 1;

my (undef, undef, $app) = File::Spec->splitpath($0);

# FTP account info
Readonly my $URL => 'ftp.gliders.ioos.us';
# Data provider user name
Readonly my $USER => 'USER';
# Data provider password
Readonly my $PASS => 'PASSWORD';
Readonly my $PORT => 21;

my $BASE_REMOTE_DIR = './upload';

# Default options
my $VERBOSE; # Net::SFTP::Foreign debugging statements
my $DELETE; # Deletes each file on successful transfer
my $SOURCE_DIR; # Directory to search for NetCDF (.nc) files
my $REMOTE_DIR; # Remote destination directory
my $WMO_FILE; # location of wmoid.txt file to upload

# Usage message
my $USAGE =<<"END_USAGE";
NAME
    $app - Secure FTP transfer of NetCDF files to IOOS NGDAC

SYNOPSIS
    $app --remote-dir DIRECTORY [--help] [--source-dir DIRECTORY] [--delete-on-success] 
        [ncfile1,ncfile2,...]

DESCRIPTION
    Upload NetCDF files to the IOOS National Glider Data Aggregation Center
    via secure ftp ($URL).  Individual files may be specified on the command 
    line.  Files are uploaded to the directory specified using the 
    --remote-dir option which, if it doesn't exist, is created under:

        $BASE_REMOTE_DIR

    Specifying a remote destination via the --remote-dir option is mandatory.

    --help
        Print help message and exit

    --remote-dir => MANDATORY
        Remote destination directory.  Specify the child directory under

            $BASE_REMOTE_DIR

    --source-dir
        Transfer all files contained in the specified directory    

    --delete-on-success
        Delete the local file copy on successful tranfer to the remote
        destination

    --wmo-file
        Path to the wmoid.txt file, if there is one.  This file will be
        uploaded if it exists

END_USAGE

# Option processing
my $options_okay = GetOptions(
    'help'  => sub { print $USAGE; exit 0 },
    'verbose' => \$VERBOSE,
    'delete-on-success' => \$DELETE,
    'source-dir=s' => \$SOURCE_DIR,
    'remote-dir=s' => \$REMOTE_DIR,
    'wmo-file=s' => \$WMO_FILE,
);
!$options_okay and exit 1;

# User MUST specify a remote location
!$REMOTE_DIR and die "No remote destination specified";

my @in_files;
# Files can come from either, in this order of preference:
# 1. A directory specified by the --source-dir option
# 2. Individual files listed on the command line
if ($SOURCE_DIR) { # Check the option first
    ! -d $SOURCE_DIR && die "Invalid directory specified: $SOURCE_DIR";
    @in_files = glob "${SOURCE_DIR}/*.nc";
}
else { # Otherwise, see if a file(s) has been specified on the command line
	# Take the list of files either from the command line or from a pipe
	if (@ARGV) { # Files from the command line
	    @in_files = grep {-f} @ARGV;
	}
	elsif (-t) { # STDIN
	    print $USAGE;
	    exit 1;
	}
	else { # Pipe
	    @in_files = <>;
	    chomp @in_files;
	}
}

#$Data::Dumper::Varname = 'Selected Files';
#print Dumper(\@in_files);

# Keep only files ending in '.nc$'
my @nc_files = grep { /\.nc$/ } @in_files;
$Data::Dumper::Varname = 'NetCDF Files';
$VERBOSE and print Dumper(\@nc_files);
#exit 13;

if (!@nc_files) {
    print "No files found for uploading.\n";
    exit 0;
}

# Connect to the remote server.  Set autodie => 1 to exit on failure
print "Connecting via FTP: $URL..";
my $ftp = Net::FTP->new($URL,
    Debug => 1,
    Passive => 1,
    Timeout => 10,
    Port => $PORT) or die "FTP connection failed: $@";
print "Connected\n";

$ftp->login($USER, $PASS) or die "FTP login failed!";

# See if the remote destination exists
my $REMOTE_DEST = "${BASE_REMOTE_DIR}/${REMOTE_DIR}";
print "REMOTE: $REMOTE_DEST\n";
my @upload_dirs = $ftp->dir($BASE_REMOTE_DIR);
$Data::Dumper::Varname = '$UPLOAD DIRS';
print Dumper(\@upload_dirs);

# Grep the directory listing for the $REMOTE_DIR
my @found_dirs = grep /$REMOTE_DIR/, @upload_dirs;
$Data::Dumper::Varname = 'FOUND REMOTE DIR';
print Dumper(\@found_dirs);

#$ftp->quit();
#exit 0;

# Create the remote directory if it doesn't already exist.  If the directory
# does not exist, the last element in @deployemnt_dir == -1
if (!@upload_dirs) {
    die
      "Remote upload destination does not exist: $REMOTE_DEST\nYou must create the upload directory using the IOOS NGDAC data provider website";
#    print "Creating NEW remote destination: $REMOTE_DEST\n";
#    my $created_dest = $ftp->mkdir($REMOTE_DEST);
#    !$created_dest and die $ftp->error;
#    print "Created: $created_dest\n";
}

# If a wmoid.txt file has been specified and is valid, upload it first
if ($WMO_FILE) {
    if ( ! -f $WMO_FILE ) { 
        warn "WMOID.txt file does not exist: $WMO_FILE\n";
    }
    else {
        print "Uploading WMO ID: $WMO_FILE\n";
	    # Create the fully-qualified remote file name
	    my (undef, undef, $wmo) = File::Spec->splitpath($WMO_FILE);
	    my $remote_wmo = File::Spec->catfile($REMOTE_DEST, $wmo);

	    # Transfer the file
	    my $success = $ftp->put($WMO_FILE, $remote_wmo);
	    if (!$success) {
	        warn "Failed transfer: $WMO_FILE (" . $ftp->error . ")\n";
	    }
    }
}

# Switch to binary transfer mode
$ftp->binary();

# Transfer each file
my $num_files = 0;
NC_FILE:
foreach my $local_nc (@nc_files) {

    # Create the fully-qualified remote file name
    my (undef, undef, $nc) = File::Spec->splitpath($local_nc);
    my $remote_nc = File::Spec->catfile($REMOTE_DEST, $nc);

    $VERBOSE and print "Transferring: $remote_nc\n";

    # Transfer the file
    my $success = $ftp->put($local_nc, $remote_nc);
    if (!$success) {
        warn "Failed transfer: $local_nc (" . $ftp->error . ")\n";
        next NC_FILE;
    }

    # Increment the file counter
    $num_files++;

    # Delete the file if specified via --delete-on-success
    if ($DELETE) {
        $VERBOSE and print "Deleting local copy: $local_nc\n";
        unlink $local_nc;
    }

}

print "${num_files}/" . scalar @nc_files . " successfully uploaded\n";
$ftp->quit();
exit 0;
