use Bio::DB::SQL::DBAdaptor;
use Bio::SeqIO;
use Getopt::Long;

my $host = "localhost";
my $sqlname = "bioperl_db";
my $dbuser = "root";
my $dbpass = undef;
my $dbname = 'embl';
my $acc;
my $stdout=0;
my $format='embl';
my $file;

&GetOptions( 'host:s' => \$host,
	     'sqldb:s'  => \$sqlname,
	     'dbuser:s' => \$dbuser,
	     'dbpass:s' => \$dbpass,
	     'dbname:s' => \$format,
	     'accession:s' => \$acc,
	     'format:s' => \$format,
	     'file:s' => \$file
	     );

$db = Bio::DB::SQL::DBAdaptor->new( -host => $host,
				    -dbname => $sqlname,
				    -user => $dbuser,
				    -pass => $dbpass
				    );
my $seqadaptor = $db->get_SeqAdaptor;
my $dbseq = $seqadaptor->fetch_by_db_and_accession("embl",$acc);

my $seqio;			

if ($file) {
    print STDERR "Going the $file way...";
    $seqio = Bio::SeqIO->new('-format' => $format,-file => ">$file");
    $seqio->write_seq($dbseq);
}
else {
    $out = Bio::SeqIO->newFh('-format' => 'EMBL'); 
    print $out $dbseq;
}





