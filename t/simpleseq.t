# -*-Perl-*-
# $Id$

use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;    
    plan tests => 27;
}

use DBTestHarness;
use Bio::SeqIO;
use Bio::Root::IO;

$biosql = DBTestHarness->new("biosql");
$db = $biosql->get_DBAdaptor();
ok $db;
$db->verbose(1) if $ENV{HARNESS_VERBOSE};

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

    my $sequk = Bio::PrimarySeq->new(-accession_number =>
				     $pseq->accession_number());
    $sequk->namespace($pseq->namespace());
    $dbseq = $db->get_object_adaptor($sequk)->find_by_unique_key($sequk);
    ok $dbseq;
    ok ($dbseq->primary_key, $pseq->primary_key());

};

print STDERR $@ if $@;

# delete seq
ok ($pseq->remove(), 1);
my $ns = Bio::DB::Persistent::BioNamespace->new(-identifiable => $pseq);
ok $ns = $db->get_object_adaptor($ns)->find_by_unique_key($ns);
ok $ns->primary_key();
ok ($ns->remove(), 1);
