#!/usr/local/bin/perl

use Bio::DB::SQL::DBAdaptor;
use Bio::SeqIO;
use Getopt::Long;

my $outfmt = 'EMBL';
my $host = "localhost";
my $sqlname = "bioperl_db";
my $dbuser = "root";
my $dbpass = undef;
my $dbname = '';
my $acc;
my $stdout=0;
my $format='embl';
my $file;
my $driver = 'mysql';

&GetOptions( 'host:s' => \$host,
             'driver:s' => \$driver,
	     'sqldb:s'  => \$sqlname,
	     'dbuser:s' => \$dbuser,
	     'dbpass:s' => \$dbpass,
	     'dbname:s' => \$dbname,
	     'accession:s' => \$acc,
	     'format:s' => \$format,
	     'outformat:s' => \$outfmt,
	     'file:s' => \$file
	     );

$dbname = shift @ARGV unless $dbname;
$acc    = shift @ARGV unless $acc;

$db = Bio::DB::SQL::DBAdaptor->new( -host => $host,
                                    -driver => $driver,
				    -dbname => $sqlname,
				    -user => $dbuser,
				    -pass => $dbpass
				    );
my $seqadaptor = $db->get_SeqAdaptor;
my $dbseq = $seqadaptor->fetch_by_db_and_accession($dbname,$acc);

my $seqio;			

if ($file) {
    print STDERR "Going the $file way...";
    $seqio = Bio::SeqIO->new('-format' => $format,-file => ">$file");
    $seqio->write_seq($dbseq);
}
else {
    $out = Bio::SeqIO->newFh('-format' => $outfmt); 
    print $out $dbseq;
}





