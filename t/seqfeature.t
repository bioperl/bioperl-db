# -*-Perl-*-
# $Id$

use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;    
    plan tests => 13;
}

use BioSQLBase;
use DBTestHarness;
use Bio::DB::SQL::DBAdaptor;
use Bio::SeqIO;

$biosql = BioSQLBase->new();
ok $biosql;

$seq = $biosql->store_seq(Bio::SeqIO->new('-format' => 'genbank',
					  '-file' => Bio::Root::IO->catfile(
					        't','data','parkin.gb')),
			  "mytestnamespace");
ok $seq;
ok $seq->primary_id();

$fadp = $biosql->db()->get_SeqFeatureAdaptor();
ok $fadp;

# set up feature and its location
$feature = Bio::SeqFeature::Generic->new;
$location = Bio::Location::Simple->new();

$location->start(1);
$location->end(10);
$location->strand(-1);

$feature->location($location);

$feature->primary_tag('tag1');
$feature->source_tag('some-source');
$feature->add_tag_value('tag12',18);
$feature->add_tag_value('tag12','another damn value');
$feature->add_tag_value('another-tag','something else');

eval {
    # store and re-retrieve
    $fid = $fadp->store($feature, 1, $seq->primary_id());
    ok $fid;
    
    $dbf = $fadp->fetch_by_dbID($fid);
    ok $dbf;
    
    ok ($feature->location->start, $dbf->location->start);
    ok ($feature->location->end, $dbf->location->end);
    ok ($feature->location->strand, $dbf->location->strand);
    
    ok (scalar($dbf->each_tag_value('tag12')), 2);
    
    ($value) = $dbf->each_tag_value('another-tag');
    
    ok( $value , 'something else');
};

print STDERR $@ if $@;

# delete seq
ok ($biosql->delete_seq($seq), 1);
ok ($biosql->delete_biodatabase("mytestnamespace"), 1);
