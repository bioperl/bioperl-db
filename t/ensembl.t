
use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;    
    plan tests => 14;
}
END { unlink( 't/ensembl_test.gb') }
use DBTestHarness;
use Bio::DB::SQL::DBAdaptor;
use Bio::SeqIO;
use Bio::Root::IO;

$harness = DBTestHarness->new();

ok $harness;


$db = $harness->get_DBAdaptor();

ok $db;


$seqio = Bio::SeqIO->new('-format' => 'GenBank',-file => Bio::Root::IO->catfile('t','data','AP000868.gb'));

$seq = $seqio->next_seq();

ok $seq;

$seqadaptor = $db->get_SeqAdaptor;

ok $seqadaptor;

$biodbadaptor = $db->get_BioDatabaseAdaptor;

$id = $biodbadaptor->fetch_by_name_store_if_needed('genbank');

$seqadaptor->store($id,$seq);

# assumme bioentry_id is 1 - probably safe ;)
$dbseq = $seqadaptor->fetch_by_dbID(1);

ok $dbseq;

ok ($dbseq->display_id eq $seq->display_id);

ok ($dbseq->accession  eq $seq->accession);

ok ($dbseq->seq        eq $seq->seq);

ok ($dbseq->subseq(3,10) eq $seq->subseq(3,10) );

ok ($dbseq->subseq(1,15) eq $seq->subseq(1,15) );

ok ($dbseq->length     == $seq->length);

ok ($dbseq->length     == length($dbseq->seq));

my $test_desc = $seq->desc;
$test_desc =~ s/\s+$//g;

ok ($dbseq->desc       eq $test_desc);


#$harness->pause;

$out = Bio::SeqIO->new( -file => '>t/ensembl_test.gb' , -"format" => 'GenBank');


$out->write_seq($dbseq);
 
ok $out;
