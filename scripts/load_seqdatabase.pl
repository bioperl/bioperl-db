#!/usr/local/bin/perl

=head1 NAME -

load_seqdatabase.pl

=head1 SYNOPSIS

   load_seqdatabase.pl -host somewhere.edu -sqldb bioperl -format swiss swiss_sptrembl swiss.dat primate.dat 

=head1 DESCRIPTION

This script loads a bioperl-db with sequences. There are a number of
options to do with where the bioperl-db database is (ie, hostname,
user for database, password, database name) followed by the database
name you wish to load this into and then any number of files. The
files are assummed to be SeqIO formatted files with the format given
in the -format flag

=cut




use Getopt::Long;
use Bio::DB::SQL::DBAdaptor;
use Bio::SeqIO;


my $host = "localhost";
my $sqlname = "new_ext_db";
my $dbuser = "root";
my $dbpass = undef;
my $format = 'embl';
#If safe is turned on, the script doesn't die because of one bad entry..
my $safe = 0;

&GetOptions( 'host:s' => \$host,
	     'sqldb:s'  => \$sqlname,
	     'dbuser:s' => \$dbuser,
	     'dbpass:s' => \$dbpass,
	     'format:s' => \$format,
	     'safe'     => \$safe
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
					   -pass => $dbpass
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









