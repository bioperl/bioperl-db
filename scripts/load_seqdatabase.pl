#!/usr/local/bin/perl

=head1 NAME 

load_seqdatabase.pl

=head1 SYNOPSIS

   load_seqdatabase.pl -host somewhere.edu -sqldb bioperl -format swiss \
     swiss_sptrembl swiss.dat primate.dat 

=head1 DESCRIPTION

This script loads a bioperl-db with sequences. There are a number of
options to do with where the bioperl-db database is (ie, hostname,
user for database, password, database name) followed by the database
name you wish to load this into and then any number of files. The
files are assumed to be SeqIO formatted files with the format given
in the -format flag

=head1 ARGUMENTS
   
   (in order, * are required)

  *-host    $URL        : the IP addy incl. port
  *-sqldb   $db_name    : the name of the sql database
  -dbuser  $username    : username
  -dbpass  $password    : password
  *-format  $FileFormat : format of the flat files (eg. embl)
                        : can be any format read by Bio::SeqIO
  -safe                 : flag to ignore errors
  -bulk    0/1          : write to tab-delim flat files (faster)
  *data_title           : A name to associate with this data
  *file1 file2 file3... : the flatfiles to import
 

=cut



use Getopt::Long;
use Bio::DB::SQL::DBAdaptor;
use Bio::SeqIO;


my $host = "localhost";
my $sqlname = "bioperl_db";
my $dbuser = "root";
my $dbpass = undef;
my $format = 'embl';
#If safe is turned on, the script doesn't die because of one bad entry..
my $safe = 0;
my $bulkload = 0;

&GetOptions( 'host:s' => \$host,
	     'sqldb:s'  => \$sqlname,
	     'dbuser:s' => \$dbuser,
	     'dbpass:s' => \$dbpass,
	     'format:s' => \$format,
	     'safe'     => \$safe,
			'bulk:s'   => \$bulkload
	     );

my $dbname = shift;
my @files = @ARGV;

if( !defined $dbname || scalar(@files) == 0 ) {
    system("perldoc $0");
    exit(0);
}

$dbadaptor = Bio::DB::SQL::DBAdaptor->new( -host => $host,
					   -dbname => $sqlname,
					   -user => $dbuser,
					   -pass => $dbpass,
						-bulk => $bulkload,
					   );

$dbid = $dbadaptor->get_BioDatabaseAdaptor->fetch_by_name_store_if_needed($dbname);
my $seqadp = $dbadaptor->get_SeqAdaptor;

foreach $file ( @files ) {

    print STDERR "Reading $file\n";
    my $seqio = Bio::SeqIO->new(-file => $file,-format => $format);

    while( $seq = $seqio->next_seq ) {
	if ($safe) {
	    eval {
		$seqadp->store($dbid,$seq);
	    };
	    if ($@) {
		print STDERR "Could not store ".$seq->accession." because of $@\n";
	    }
	}
	else {
	    $seqadp->store($dbid,$seq);
	}
    }
}









