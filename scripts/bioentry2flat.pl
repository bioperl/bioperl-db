use Bio::DB::SQL::DBAdaptor;
use Bio::SeqIO;
use Getopt::Long;

my $host = "localhost";
my $sqlname = "bioperl_db";
my $dbuser = "root";
my $dbpass = undef;
my $dbname = 'embl';
my $acc;
my $format='fasta';
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

if (!$file) { 
    $file="$acc.$format";
}
$file = ">$file";
$db = Bio::DB::SQL::DBAdaptor->new( -host => $host,
				    -dbname => $sqlname,
				    -user => $dbuser,
				    -pass => $dbpass
				    );

my $seqio = Bio::SeqIO->new('-format' => $format,-file => $file);

my $seqadaptor = $db->get_SeqAdaptor;

# assumme bioentry_id is 1 - probably safe ;)
my $dbseq = $seqadaptor->fetch_by_db_and_accession("embl",$acc);
$seqio->write_seq($dbseq);



