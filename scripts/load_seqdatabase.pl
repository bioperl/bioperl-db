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
in the -format flag.

Loading large numbers of e.g. embl files can take a long time
(many hours).  A boolean flag has been added, '-bulk',which allows
you to load the flatfile into a tab-delimited set of output files
in your /tmp/ folder (*.bulk) which may then be imported en masse
using e.g. mysqlimport


=head1 ARGUMENTS
   
  The last two arguments are data_title, and then the filelist.
  These are the only args that are absolutely required.
  Default values for each parameter are shown in brackets:

  -host    $URL        : the IP addy incl. port (localhost)
  -sqldb   $db_name    : the name of the sql database (bioperl_db)
  -dbuser  $username   : username (root)
  -dbpass  $password   : password (undef)
  -format  $FileFormat : format of the flat files (embl)
                       : Can be any format read by Bio::SeqIO
  -safe                : flag to ignore errors
  -bulk    0/1         : write to tab-delim flat files (0)
                       : this cuts down loading time by about
                       : half, including the manual mysqlimport.
  *data_title          : A name to associate with this data
  *file1 file2 file3...: the flatfiles to import
 

=cut



use Getopt::Long;
use Bio::DB::SQL::DBAdaptor;
use Bio::SeqIO;


my $host = "localhost";
my $sqlname = "biosql";
my $dbuser = "root";
my $driver = 'mysql';
my $dbpass = undef;
my $format = 'genbank';
my $removeflag = '';
#If safe is turned on, the script doesn't die because of one bad entry..
my $safe = 0;
my $bulkload = 0;

&GetOptions( 'host:s' => \$host,
             'driver:s' => \$driver,
	     'sqldb:s'  => \$sqlname,
	     'dbuser:s' => \$dbuser,
	     'dbpass:s' => \$dbpass,
	     'format:s' => \$format,
	     'safe'     => \$safe,
	     'remove'     => \$remove,
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
                                           -driver=> $driver,
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
        if ($removeflag) {
            my $oldseq =
              $seqadp->remove_by_db_and_accession($dbname, $seq->accession);
        }
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









