# -*-Perl-*-
# $Id$

use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;
    plan tests => 21, todo => [17]; # test #17 is for optional_id() in DBLink
}

# -----------------------------------------------
# REQUIREMENTS TESTED: (not yet!)
# unknown start/end (eg like we find in SP)
# must be handled gracefully
# cjm@fruitfly.org
# -----------------------------------------------

use DBTestHarness;
use Bio::SeqIO;
use Bio::Root::IO;

$biosql = DBTestHarness->new("biosql");
$db = $biosql->get_DBAdaptor();
ok $db;
$db->verbose(1) if $ENV{HARNESS_VERBOSE};

my $seqio = Bio::SeqIO->new('-format' => 'embl',
			    '-file' => Bio::Root::IO->catfile(
						 't','data','AB030700.embl'));
my $seq = $seqio->next_seq();
ok $seq;
my $pseq = $db->create_persistent($seq);
$pseq->namespace("mytestnamespace");
$pseq->create();
ok $pseq->primary_key();

my $seqadp = $db->get_object_adaptor($seq);
ok $seqadp;

eval {
    my $sequk = Bio::Seq::RichSeq->new(-accession_number => "AB030700",
				       -version   => 1,
				       -namespace => "mytestnamespace");
    $dbseq = $seqadp->find_by_unique_key($sequk);
    ok $dbseq;

    ok ($dbseq->display_id, $seq->display_id);
    ok ($dbseq->accession, $seq->accession);
    ok ($dbseq->subseq(3,10), $seq->subseq(3,10) );
    ok ($dbseq->subseq(1,15), $seq->subseq(1,15) );
    ok ($dbseq->length, $seq->length);
    ok ($dbseq->seq, $seq->seq);
    ok ($dbseq->desc, $seq->desc);

    @dblinks = sort {
	$a->primary_id cmp $b->primary_id
	} $dbseq->annotation->get_Annotations('dblink');
    @stdlinks = sort {
	$a->primary_id cmp $b->primary_id
	} $seq->annotation->get_Annotations('dblink');

    ok (scalar(@dblinks));
    ok (scalar(@dblinks), scalar(@stdlinks));

    for(my $i = 0; $i < @dblinks; $i++) {
	ok($dblinks[$i]->database, $stdlinks[$i]->database);
	ok($dblinks[$i]->primary_id, $stdlinks[$i]->primary_id);
	ok($dblinks[$i]->optional_id, $stdlinks[$i]->optional_id);
    }
};

print STDERR $@ if $@;

# delete seq
ok ($pseq->remove(), 1);
my $ns = Bio::DB::Persistent::BioNamespace->new(-identifiable => $pseq);
ok $ns = $db->get_object_adaptor($ns)->find_by_unique_key($ns);
ok $ns->primary_key();
ok ($ns->remove(), 1);

