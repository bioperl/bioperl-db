# -*-Perl-*- mode (to keep my emacs happy)
# $Id$

use lib 't';

BEGIN {     
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;

    plan tests => 110;
}

use DBTestHarness;
use Bio::SeqIO;
use Bio::Root::IO;
use Bio::Seq::SeqFactory;

$biosql = DBTestHarness->new("biosql");
$db = $biosql->get_DBAdaptor();
ok $db;
$db->verbose(1) if $ENV{HARNESS_VERBOSE};

my $seqin = Bio::SeqIO->new(-file => Bio::Root::IO->catfile("t","data",
							    "LL-sample.seq"),
			    -format => 'locuslink');
ok $seqin;

my $seq = $seqin->next_seq();
ok $seq;

my $pseq = $db->create_persistent($seq);
ok $pseq;

$pseq->namespace("mytestnamespace");
$pseq->accession_number("999999999"); # don't clash with something existing
ok $pseq->create();
ok $pseq->primary_key();

my $adp = $db->get_object_adaptor($seq);
ok $adp;
my $seqfact = Bio::Seq::SeqFactory->new(-type => "Bio::Seq::RichSeq");
ok $seqfact;

# try/finally
eval {
    $dbseq = $adp->find_by_primary_key($pseq->primary_key(), $seqfact);
    ok $dbseq;

    ok ($dbseq->desc, $seq->desc);
    ok ($dbseq->accession_number, $seq->accession_number);
    ok ($dbseq->display_id, $seq->display_id);
    ok ($dbseq->species->binomial, "Homo sapiens");


    my @dblinks = $dbseq->annotation->get_Annotations('dblink');
    my %dbcounts = map { ($_->database(),0) } @dblinks;
    foreach (@dblinks) { $dbcounts{$_->database()}++; }

    # We need to remove duplicated dblinks as neither in bioperl nor in biosql
    # we have context for dblinks. The problem is that the locuslink
    # parser currently adds the value for the ASSEMBLY tag as a dblink, and
    # that one might occur later, too (as a real dbxref).
    my @links = $seq->annotation->remove_Annotations('dblink');
    my %xrefs = map { ($_->database .":". $_->primary_id, $_); } @links;
    @links = values %xrefs;
    foreach (@links) { $seq->annotation->add_Annotation($_); }
    # now count ...
    my %counts = map { ($_->database(),0) } @links;
    foreach (@links) { $counts{$_->database()}++; }

    foreach my $k (keys %counts) {
	ok ($dbcounts{$k}, $counts{$k}, "unequal counts for $k");
    }
    ok (scalar(@dblinks), scalar(@links));

    my $dbac = $dbseq->annotation;
    my $ac = $seq->annotation;
    
    # LocusLink annotates GO terms with their GO sub-division as the category,
    # which isn't really the correct thing to do. If we run this script on a
    # database into which GO was loaded already, we'll find the terms by their
    # IDs - and then the category (tagname) will change to Gene Ontology. We
    # try to fix this possible discrepancy here.
    my ($t1) = grep {
	$_->isa("Bio::Ontology::TermI") && $_->identifier eq "GO:0008152"; 
    } $dbac->get_Annotations();
    my ($t2) = grep { 
	$_->isa("Bio::Ontology::TermI") && $_->identifier eq "GO:0005777"; 
    } $dbac->get_Annotations();
    my ($t3) = grep { 
	$_->isa("Bio::Ontology::TermI") && $_->identifier eq "GO:0008131"; 
    } $dbac->get_Annotations();
    my %tagnames = ("biological process" => $t1->ontology->name,
		    "cellular component" => $t2->ontology->name,
		    "molecular function" => $t3->ontology->name);
    foreach my $tag (keys %tagnames) {
	if($tag ne $tagnames{$tag}) {
	    # we need to fix this one before we can compare
	    map { $_->tagname($tagnames{$tag}); $ac->add_Annotation($_);
	      } $ac->remove_Annotations($tag);
	}
    }
    my %uniquenames = map { ($_, undef); } values %tagnames;
    # we also need to make up for tests that we won't conduct
    # (namely the count comparison per annotation key)
    for (1..(3-scalar(values %uniquenames))) {
	skip("GO sub-division tag became GO name", $tag);
    }

    my @keys = $ac->get_all_annotation_keys();
    ok (scalar($dbac->get_all_annotation_keys()), scalar(@keys));

    foreach my $k (@keys) {
	my @dbanns =
	    sort { $a->as_text() cmp $b->as_text } $dbac->get_Annotations($k);
	my @anns = 
	    sort { $a->as_text() cmp $b->as_text } $ac->get_Annotations($k);
	ok (scalar(@dbanns), scalar(@anns), "unequal counts for $k");
	for(my $i = 0; $i < @anns; $i++) {
	    ok ($dbanns[$i]->as_text, $anns[$i]->as_text);
	}
    }

    my ($dbcmt) = $dbac->get_Annotations('comment');
    my ($cmt) = $ac->get_Annotations('comment');
    ok ($dbcmt->text, $cmt->text);
};

print STDERR $@ if $@;

# delete seq
ok ($pseq->remove(), 1);
my $ns = Bio::DB::Persistent::BioNamespace->new(-identifiable => $pseq);
ok $ns = $db->get_object_adaptor($ns)->find_by_unique_key($ns);
ok $ns->primary_key();
ok ($ns->remove(), 1);

