# -*-Perl-*-
# $Id$

use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;    
    plan tests => 59;
}

use DBTestHarness;
use Bio::SeqIO;
use Bio::Root::IO;

$biosql = DBTestHarness->new("biosql");
$db = $biosql->get_DBAdaptor();
ok $db;

my $seqio = Bio::SeqIO->new('-format' => 'fasta',
			    '-file' => Bio::Root::IO->catfile('t','data',
							      'parkin.fasta'));
my $seq = $seqio->next_seq();
ok $seq;

my $pseq = $db->create_persistent($seq);
ok $pseq;
ok $pseq->isa("Bio::DB::PersistentObjectI");
ok $pseq->isa("Bio::PrimarySeqI");

$pseq->namespace("mytestnamespace");
$pseq->store();
my $dbid = $pseq->primary_key();
ok $dbid;

# test long sequence
$seqio->close();
$seqio = Bio::SeqIO->new('-format' => 'fasta',
                         '-file' => 
                         "gzip -d -c "
                         . Bio::Root::IO->catfile('t','data','Titin.fasta.gz')
                         . '|');
my $lseq = $seqio->next_seq();
$seqio->close();
$lseq->namespace("mytestnamespace");
my ($acc) = grep { /^NM/ } split(/\|/, $lseq->primary_id);
$acc =~ s/\.(\d+)$//;
$lseq->version($1);
$lseq->accession_number($acc);
$lseq->primary_id(undef);
$lseq->display_id($acc);
ok ($lseq->accession_number, "NM_003319");
ok ($lseq->version, 2);
ok ($lseq->length, 82027);
my $plseq = $db->create_persistent($lseq);
$plseq->create();

my $adp = $db->get_object_adaptor($seq);
ok $adp;
ok $adp->isa("Bio::DB::PersistenceAdaptorI");

# start try/finally
eval {
    my $dbseq = $adp->find_by_primary_key($dbid);
    ok $dbseq;
    ok ($dbseq->primary_key(), $dbid);

    ok ($dbseq->display_id, $seq->display_id);
    ok ($dbseq->accession_number, $seq->accession_number);
    ok ($dbseq->namespace, $seq->namespace);
    # the following two may take different call paths depending on whether the
    # sequence has been requested yet or not
    ok ($dbseq->length, $seq->length);
    ok ($dbseq->subseq(3,10), $seq->subseq(3,10) );
    ok ($dbseq->seq, $seq->seq);
    ok ($dbseq->subseq(3,10), $seq->subseq(3,10) );
    ok ($dbseq->subseq(1,15), $seq->subseq(1,15) );
    ok ($dbseq->length, $seq->length);
    ok ($dbseq->length, length($dbseq->seq));
    ok ($dbseq->desc, $seq->desc);

    my $sequk = Bio::PrimarySeq->new(
			      -accession_number => $pseq->accession_number(),
			      -namespace => $pseq->namespace());
    $dbseq = $db->get_object_adaptor($sequk)->find_by_unique_key($sequk);
    ok $dbseq;
    ok ($dbseq->primary_key, $pseq->primary_key());

    # test correct retrieval of long sequence
    $sequk = Bio::PrimarySeq->new(-accession_number =>$lseq->accession_number,
                                  -version => $lseq->version,
                                  -namespace => $lseq->namespace);
    $dbseq = $db->get_object_adaptor($sequk)->find_by_unique_key($sequk);
    ok $dbseq;
    ok ($dbseq->accession_number, $lseq->accession_number);
    ok ($dbseq->length, $lseq->length);
    ok ($dbseq->namespace, $lseq->namespace);
    ok ($dbseq->version, $lseq->version);
    ok ($dbseq->subseq(40100,40400), $lseq->subseq(40100,40400));
    ok ($dbseq->seq, $lseq->seq);

    # test correct update of properties if seq object is updated (but
    # not the sequence)
    $dbseq->version($lseq->version() + 1);
    ok $dbseq->store();
    $sequk = Bio::PrimarySeq->new(-accession_number =>$lseq->accession_number,
                                  -version => $lseq->version() + 1,
                                  -namespace => $lseq->namespace);
    $dbseq = $db->get_object_adaptor($sequk)->find_by_unique_key($sequk);
    ok ($dbseq->length, $lseq->length);
    ok ($dbseq->version, $lseq->version() + 1);
    ok ($dbseq->subseq(40100,40400), $lseq->subseq(40100,40400));
    ok ($dbseq->seq, $lseq->seq);

    # test correct update of properties if seq object is not updated
    ok !$dbseq->is_dirty;
    ok $dbseq->store();
    $sequk = Bio::PrimarySeq->new(-accession_number =>$lseq->accession_number,
                                  -version => $lseq->version() + 1,
                                  -namespace => $lseq->namespace);
    $dbseq = $db->get_object_adaptor($sequk)->find_by_unique_key($sequk);
    ok ($dbseq->length, $lseq->length);
    ok ($dbseq->version, $lseq->version() + 1);
    ok ($dbseq->subseq(40100,40400), $lseq->subseq(40100,40400));
    ok ($dbseq->seq, $lseq->seq);

    # test whether a null sequence will not clobber the sequence in
    # the database
    $dbseq->seq(undef);
    ok ($dbseq->length, 0);
    ok ($dbseq->seq, undef);
    $dbseq->length($lseq->length);
    ok ($dbseq->seq, undef);
    ok ($dbseq->length, $lseq->length);
    ok $dbseq->is_dirty;
    ok $dbseq->store;
    # re-retrieve and test
    $sequk = Bio::PrimarySeq->new(-accession_number =>$lseq->accession_number,
                                  -version => $lseq->version() + 1,
                                  -namespace => $lseq->namespace);
    $dbseq = $db->get_object_adaptor($sequk)->find_by_unique_key($sequk);
    ok ($dbseq->length, $lseq->length);
    ok ($dbseq->version, $lseq->version() + 1);
    ok ($dbseq->subseq(40100,40400), $lseq->subseq(40100,40400));
    ok ($dbseq->seq, $lseq->seq);

    # remove the long sequence ...
    ok $plseq->remove;
};

print STDERR $@ if $@;

# delete seq and namespace
ok ($pseq->remove(), 1);
my $ns = Bio::DB::Persistent::BioNamespace->new(-identifiable => $pseq);
ok $ns = $db->get_object_adaptor($ns)->find_by_unique_key($ns);
ok $ns->primary_key();
ok ($ns->remove(), 1);
