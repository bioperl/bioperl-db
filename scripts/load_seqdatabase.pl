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


=head1 ARGUMENTS

  The arguments after the named options constitute the filelist. If
  there are no such files, input is read from stdin. Mandatory options
  are marked by (M). Default values for each parameter are shown in
  brackets.  (Note that -bulk is no longer available):

  -host    $URL        : the IP addy incl. port (localhost)
  -sqldb   $db_name    : the name of the sql database (biosql) (M)
  -dbuser  $username   : username (root)
  -dbpass  $password   : password (undef)
  -driver  $driver     : the DBI driver name for the RDBMS
                         e.g., mysql, Pg, or oracle (mysql)
  -format  $FileFormat : format of the flat files (genbank),
                         can be any format read by Bio::SeqIO
  -namespace $namesp   : the namespace under which the sequences in the
                         input files are to be created in the database 
                         (bioperl)
  -safe                : flag to ignore errors
  *file1 file2 file3...: the flatfiles to import
 

=cut


use Getopt::Long;
use Bio::DB::BioDB;
use Bio::SeqIO;

####################################################################
# Defaults for options changeable through command line
####################################################################
my $host = "localhost";
my $sqlname = "biosql";
my $dbuser = "root";
my $driver = 'mysql';
my $dbpass = undef;
my $format = 'genbank';
my $removeflag = '';
my $namespace = "bioperl";
#If safe is turned on, the script doesn't die because of one bad entry..
my $safe = 0;
####################################################################
# End of defaults
####################################################################

&GetOptions( 'host:s' => \$host,
             'driver:s' => \$driver,
	     'sqldb:s'  => \$sqlname,
	     'dbuser:s' => \$dbuser,
	     'dbpass:s' => \$dbpass,
	     'format:s' => \$format,
	     'safe'     => \$safe,
	     'remove'     => \$remove,
	     );

my @files = @ARGV;
# if no files, assume stdin
if(! @files) {
    push(@files, \*STDIN);
}

if( !defined $dbname || scalar(@files) == 0 ) {
    system("perldoc $0");
    exit(0);
}

my $dbc = Bio::DB::SimpleDBContext->new( -host => $host,
					 -dbname => $sqlname,
					 -driver=> $driver,
					 -user => $dbuser,
					 -pass => $dbpass,
					);
my $db = Bio::DB::BioDB->new(-database => "biosql", -dbcontext => $dbc);

foreach $file ( @files ) {

    my $seqin;
    if(ref($file)) {
	$seqin = Bio::SeqIO->new(-fh => $file, -format => $format);
    } else {
	print STDERR "Loading $file\n";
	$seqin = Bio::SeqIO->new(-file => $file,
				 $format ? -format => $format : ());
    }

    while( my $seq = $seqio->next_seq ) {
	# don't forget to add namespace if the parser doesn't supply one
	$seq->namespace($namespace) unless $seq->namespace();
	# create a persistent object out of the seq
	my $pseq;
	# delete first?
        if ($removeflag) {
	    $pseq = $db->get_object_adaptor($seq)->find_by_unique_key($seq);
	    $pseq->remove() if($pseq);
        } else {
	    $pseq = $db->create_persistent($seq);
	}
	# try to serialize
	eval {
	    $pseq->create();
	    $pseq->commit();
	};
	if ($@) {
	    $pseq->rollback();
	    my $msg = "Could not store ".$seq->accession.": $@\n";
	    if($safe) {
		$pseq->warn($msg);
	    } else {
		$pseq->throw($msg);
	    }
	}
    }
}









