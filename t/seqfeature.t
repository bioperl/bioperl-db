# -*-Perl-*-
# $Id$

use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;    
    plan tests => 19;
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
						      't','data','parkin.gb'));
my $seq = $seqio->next_seq();
ok $seq;
my $pseq = $db->create_persistent($seq);
$pseq->namespace("mytestnamespace");

# set up feature and its location
$feat = Bio::SeqFeature::Generic->new;
$loc = Bio::Location::Simple->new();

$loc->start(1);
$loc->end(10);
$loc->strand(-1);

$feat->location($loc);

$feat->primary_tag('tag1');
$feat->source_tag('some-source');
$feat->add_tag_value('tag12',18);
$feat->add_tag_value('tag12','another damn value');
$feat->add_tag_value('another-tag','something else');

# make persistent
my $pfeat = $db->create_persistent($feat);
ok $pfeat->isa("Bio::DB::PersistentObjectI");

# store seq
$pseq->store();
ok $pseq->primary_key();

# attach seq (the foreign key)
$pfeat->attach_seq($pseq);

# try/finally (we need to make sure the seq is removed at the end of the test)
eval {
    # store the feature (this will actually be a create)
    $pfeat->store();
    ok $pfeat->primary_key();

    # and re-retrieve
    $fadp = $db->get_object_adaptor($feat);
    ok $fadp;
    $dbf = $fadp->find_by_primary_key($pfeat->primary_key());
    ok $dbf;
    ok ($dbf->primary_key, $feat->primary_key);
    ok ($dbf->primary_tag, $feat->primary_tag);
    ok ($dbf->source_tag, $feat->source_tag);
    
    ok ($dbf->location->start, $feat->location->start);
    ok ($dbf->location->end, $feat->location->end);
    ok ($dbf->location->strand, $feat->location->strand);
    
    ok (scalar($dbf->each_tag_value('tag12')), 2);
    
    ($value) = $dbf->each_tag_value('another-tag');
    
    ok( $value , 'something else');
};

print STDERR $@ if $@;

# delete seq
ok ($pseq->remove(), 1);
my $ns = Bio::DB::Persistent::BioNamespace->new(-identifiable => $pseq);
ok $ns = $db->get_object_adaptor($ns)->find_by_unique_key($ns);
ok $ns->primary_key();
ok ($ns->remove(), 1);
