#!/usr/local/bin/perl

=head1 NAME -

load_seqdatabase.pl

=head1 SYNOPSIS

   load_seqdatabase.pl -host somewhere.edu -sqldb bioperl swiss_sptrembl swiss.dat primate.dat 

=head1 DESCRIPTION

This script loads a bioperl-db with sequences.

=cut




use Getopt::Long;
use Bio::DB::SQL::DBAdaptor;

my $host = "localhost";
my $sqlname = "bioperl";
my $dbuser = "root";
my $dbpass = undef;
my $format = 'fasta';

&GetOptions( 'host:s' => \$host,
	     'sqldb:s'  => \$sqlname,
	     'dbuser:s' => \$dbuser,
	     'dbpass:s' => \$dbpass
	     );

my $dbname = shift;
my @files = @ARGV;

if( !defined $dbname || scalar(@files) == 0 ) {
    system("perldoc $0");
    exit(0);
}

$dbadaptor = Bio::DB::SQL::DBAdaptor->new( -host => $host,
					   -dbname => $sqlname,
					   -dbuser => $dbuser,
					   -pass => $dbpass
					   );

$dbid = $dbadaptor->get_BioDatabaseAdaptor->fetch_by_name_store_if_needed($dbname);
my $seqadp = $dbadaptor->get_SeqAdaptor;

foreach $file ( @files ) {

    my $seqio = Bio::SeqIO->new(-file => $file,-format => $format);

    while( $seq = $seqio->next_seq ) {
	$seqadp->store($seq);
    }
}



