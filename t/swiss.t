use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;    
    plan tests => 16;
}

use DBTestHarness;
use Bio::DB::SQL::DBAdaptor;
use Bio::SeqIO;

$harness = DBTestHarness->new();

ok $harness;


$db = $harness->get_DBAdaptor();

ok $db;


$seqio = Bio::SeqIO->new('-format' => 'swiss',-file => 't/swiss.dat');

$seq = $seqio->next_seq();

ok $seq;

$seqadaptor = $db->get_SeqAdaptor;

ok $seqadaptor;

$biodbadaptor = $db->get_BioDatabaseAdaptor;

$id = $biodbadaptor->fetch_by_name_store_if_needed('swissprot');

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

@dblinks = $dbseq->annotation->each_DBLink;
@stdlinks = $seq->annotation->each_DBLink;

ok (scalar(@dblinks));
ok (scalar(@stdlinks));


@dblinks = sort { $a->primary_id cmp $b->primary_id } @dblinks;

@stdlinks = sort { $a->primary_id cmp $b->primary_id } @stdlinks;

$dl1 = shift @dblinks;
$std1 = shift @stdlinks;

ok ( $dl1->primary_id eq $std1->primary_id);

