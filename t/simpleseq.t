

use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;    
    plan tests => 20;
}

use DBTestHarness;
use Bio::DB::SQL::DBAdaptor;
use Bio::SeqIO;
use Bio::Root::IO;
$harness = DBTestHarness->new();

ok $harness;


$db = $harness->get_DBAdaptor();

ok $db;


$seqio = Bio::SeqIO->new('-format' => 'GenBank',-file => Bio::Root::IO->catfile('t','data','parkin.gb'));

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


$dbseq = $seqadaptor->fetch_by_db_and_accession("genbank",$seq->accession);

ok $dbseq;

my ($source,$cds) = $dbseq->top_SeqFeatures;

ok $source;

ok ($cds->start == 71 );

ok ($cds->end   == 1465 );

#$harness->pause;

($dbxref) = $cds->each_tag_value('db_xref');

ok ($dbxref eq 'GI:5456930');


$biodb = $db->get_BioDatabaseAdaptor->fetch_BioSeqDatabase_by_name("genbank");

ok $biodb;

$dbseq = $biodb->get_Seq_by_acc($seq->accession);

ok $dbseq;




