# -*-Perl-*-
# $Id$

use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;    
    plan tests => 40;
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
$feat->start(1);
$feat->end(10);
$feat->strand(-1);

$feat->primary_tag('tag1');
$feat->source_tag('some-source');
$feat->add_tag_value('tag12',18);
$feat->add_tag_value('tag12','another damn value');
$feat->add_tag_value('another-tag','something else');

# make persistent
my $pfeat = $db->create_persistent($feat);
ok $pfeat->isa("Bio::DB::PersistentObjectI");

# store seq
$pseq->create();
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
    ok ($dbf->primary_key, $pfeat->primary_key);
    ok ($dbf->primary_tag, $feat->primary_tag);
    ok ($dbf->source_tag, $feat->source_tag);
    
    ok ($dbf->location->start, $feat->location->start);
    ok ($dbf->location->end, $feat->location->end);
    ok ($dbf->location->strand, $feat->location->strand);
    ok ! $dbf->location->is_remote;
    
    ok (scalar($dbf->get_tag_values('tag12')), 2);
    
    ($value) = $dbf->get_tag_values('another-tag');
    ok( $value , 'something else');

    print STDERR "\n------------\n".
	"be prepared to see 3 failed statement warnings, ".
	"and one Bioperl-style warning\ntrust me, this is OK ...\n".
	"------------\n";
    # add a tag value and update
    $dbf->add_tag_value('tag13','value for tag13');
    $dbf->attach_seq($pseq); # we need a FK seq to successfully update
    ok ! $dbf->store(); # this works but still should return FALSE due to
                        # caught UK violations (only 1 tag/value is new!)
    # re-retrieve by seq
    my $dbseq = $db->get_object_adaptor("Bio::SeqI")->find_by_primary_key(
						           $pseq->primary_key);
    ok $dbseq;
    ($dbf) = grep { $_->primary_tag eq 'tag1'; } $dbseq->top_SeqFeatures();
    ok $dbf;
    # check previous tags and for added tag
    ok (scalar($dbf->get_tag_values('tag12')), 2);
    ($value) = $dbf->get_tag_values('another-tag');
    ok( $value , 'something else');
    ($value) = $dbf->get_tag_values('tag13');
    ok( $value , 'value for tag13');

    # test remote feature locations
    # without explicit namespace:
    ok ($pfeat->remove(), 1);
    $pfeat->location->is_remote(1);
    $pfeat->location->seq_id('AB123456');
    $pfeat->create();
    # re-retrieve and test
    $dbf = $fadp->find_by_primary_key($pfeat->primary_key());
    ok $dbf;
    ok ($dbf->primary_key, $pfeat->primary_key);
    ok ($dbf->start, 1);
    ok ($dbf->end, 10);
    ok $dbf->location->is_remote;
    ok ($dbf->location->seq_id, "mytestnamespace:AB123456");
    # without explicit namespace:
    ok ($pfeat->remove(), 1);
    $pfeat->location->is_remote(1);
    $pfeat->location->seq_id('XZ:AB123456.4');
    $pfeat->create();
    # re-retrieve and test
    $dbf = $fadp->find_by_primary_key($pfeat->primary_key());
    ok $dbf;
    ok ($dbf->primary_key, $pfeat->primary_key);
    ok ($dbf->start, 1);
    ok ($dbf->end, 10);
    ok $dbf->location->is_remote;
    ok ($dbf->location->seq_id, "XZ:AB123456.4");
    
};

print STDERR $@ if $@;

# delete seq
ok ($pseq->remove(), 1);
my $ns = Bio::DB::Persistent::BioNamespace->new(-identifiable => $pseq);
ok $ns = $db->get_object_adaptor($ns)->find_by_unique_key($ns);
ok $ns->primary_key();
ok ($ns->remove(), 1);
