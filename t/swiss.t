# -*-Perl-*-
# $Id$

use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;
    plan tests => 37;
}

use DBTestHarness;
use Bio::SeqIO;
use Bio::Root::IO;
use Bio::Seq::SeqFactory;

$biosql = DBTestHarness->new("biosql");
$db = $biosql->get_DBAdaptor();
ok $db;
$db->verbose(1) if $ENV{HARNESS_VERBOSE};

my $seqio = Bio::SeqIO->new('-format' => 'swiss',
			    '-file' => Bio::Root::IO->catfile(
						      't','data','swiss.dat'));
my $seq = $seqio->next_seq();
ok $seq;

my $pseq = $db->create_persistent($seq);
ok $pseq;
ok $pseq->isa("Bio::DB::PersistentObjectI");
ok $pseq->isa("Bio::SeqI");

$pseq->namespace("mytestnamespace");
$pseq->store();
my $dbid = $pseq->primary_key();
ok $dbid;

my $adp = $db->get_object_adaptor($seq);
ok $adp;
ok $adp->isa("Bio::DB::PersistenceAdaptorI");

my $seqfact = Bio::Seq::SeqFactory->new(-type => "Bio::Seq::RichSeq");
ok $seqfact;
ok $seqfact->isa("Bio::Factory::ObjectFactoryI");

# try/finally
eval {
    $dbseq = $adp->find_by_primary_key($dbid, $seqfact);
    ok $dbseq;

    ok ($dbseq->display_id, $seq->display_id);
    ok ($dbseq->primary_id, $seq->primary_id);
    ok ($dbseq->accession_number, $seq->accession_number);
    ok ($dbseq->species->binomial, $seq->species->binomial);
    ok ($dbseq->subseq(3,10), $seq->subseq(3,10) );
    ok ($dbseq->seq, $seq->seq);
    ok ($dbseq->length, $seq->length);
    ok ($dbseq->length, length($dbseq->seq));

    ok ($dbseq->desc, $seq->desc);

    my @dbarr = $dbseq->annotation->get_Annotations('dblink');
    my @arr = $seq->annotation->get_Annotations('dblink');
    ok (scalar(@dbarr), scalar(@arr));

    @dbarr = sort { $a->primary_id cmp $b->primary_id } @dbarr;
    @arr = sort { $a->primary_id cmp $b->primary_id } @arr;
    ok ( $dbarr[0]->primary_id, $arr[0]->primary_id);

    @dbarr = $dbseq->annotation->get_Annotations('reference');
    @arr = $seq->annotation->get_Annotations('reference');
    ok (scalar(@dbarr), scalar(@arr));

    @dbarr = sort { $a->primary_id cmp $b->primary_id } @dbarr;
    @arr = sort { $a->primary_id cmp $b->primary_id } @arr;
    ok ( $dbarr[0]->primary_id, $arr[0]->primary_id);

    ok (scalar(grep { $_->start() && $_->end(); } @dbarr),
	scalar(grep { $_->start() && $_->end(); } @arr));

    @dbarr = $dbseq->annotation->get_Annotations('gene_name');
    @arr = $seq->annotation->get_Annotations('gene_name');
    ok (scalar(@dbarr), scalar(@arr));
    @dbarr = sort { $a->value() cmp $b->value() } @dbarr;
    @arr = sort { $a->value() cmp $b->value() } @arr;
    for(my $i = 0; $i < @dbarr; $i++) {
	ok ($dbarr[$i]->value(), $arr[$i]->value());
    }

    @dbarr = $dbseq->top_SeqFeatures();
    @arr = $seq->top_SeqFeatures();
    ok (scalar(@dbarr), scalar(@arr));
    @dbarr = sort { $a->primary_tag() cmp $b->primary_tag() } @dbarr;
    @arr = sort { $a->primary_tag() cmp $b->primary_tag() } @arr;
    for(my $i = 0; $i < @dbarr; $i++) {
	ok ($dbarr[$i]->primary_tag(), $arr[$i]->primary_tag());
    }

};

print STDERR $@ if $@;

# delete seq
ok ($pseq->remove(), 1);
my $ns = Bio::DB::Persistent::BioNamespace->new(-identifiable => $pseq);
ok $ns = $db->get_object_adaptor($ns)->find_by_unique_key($ns);
ok $ns->primary_key();
ok ($ns->remove(), 1);
