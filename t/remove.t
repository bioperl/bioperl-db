# -*-Perl-*-
# $Id$

use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;    
    plan tests => 51;
}

use DBTestHarness;
use Bio::SeqIO;
use Bio::Root::IO;

$biosql = DBTestHarness->new("biosql");
$db = $biosql->get_DBAdaptor();
ok $db;
$db->verbose(1) if $ENV{HARNESS_VERBOSE};

my $seqio = Bio::SeqIO->new('-format' => 'genbank',
			    '-file' => Bio::Root::IO->catfile(
						   't','data','test.genbank'));

my ($seq, $pseq);
my @seqs = ();
my @arr = ();

eval {
    my $pk = -1;
    while($seq = $seqio->next_seq()) {
	$pseq = $db->create_persistent($seq);
	$pseq->namespace("mytestnamespace");
	$pseq->create();
	ok $pseq->primary_key();
	ok $pseq->primary_key() != $pk;
	$pk = $pseq->primary_key();
	push(@seqs, $pseq);
    }
    ok (scalar(@seqs), 4);
    $pseq = @seqs[$#seqs];

    $seqadp = $db->get_object_adaptor("Bio::SeqI");
    ok $seqadp;

    # re-fetch from database
    $pseq = $seqadp->find_by_primary_key($pseq->primary_key());
    
    # features
    @arr = $pseq->top_SeqFeatures();
    ok (scalar(@arr), 26);

    # references
    @arr = $pseq->annotation()->get_Annotations("reference");
    ok (scalar(@arr), 1);

    # all feature qualifier/value pairs
    @arr = ();
    foreach my $feat ($pseq->top_SeqFeatures()) {
	foreach ($feat->all_tags()) {
	    push(@arr, $feat->each_tag_value($_));
	}
    }
    ok (scalar(@arr), 38);

    # delete all features
    foreach my $feat ($pseq->top_SeqFeatures()) {
	ok ($feat->remove(), 1);
    }

    # delete all references
    foreach my $ref ($pseq->annotation()->get_Annotations("reference")) {
	ok ($ref->remove(), 1);
    }

    # re-fetch sequence and retest
    $pseq = $seqadp->find_by_primary_key($pseq->primary_key());
    
    # features
    @arr = $pseq->top_SeqFeatures();
    ok (scalar(@arr), 0);

    # references
    @arr = $pseq->annotation()->get_Annotations("reference");
    ok (scalar(@arr), 0);

    # all feature qualifier/value pairs
    @arr = ();
    foreach my $feat ($pseq->top_SeqFeatures()) {
	foreach ($feat->all_tags()) {
	    push(@arr, $feat->each_tag_value($_));
	}
    }
    ok (scalar(@arr), 0);

};

print STDERR $@ if $@;

# delete seq
foreach $pseq (@seqs) {
    ok ($pseq->remove(), 1);
}
my $ns = Bio::DB::Persistent::BioNamespace->new(-identifiable => $pseq);
ok $ns = $db->get_object_adaptor($ns)->find_by_unique_key($ns);
ok $ns->primary_key();
ok ($ns->remove(), 1);

