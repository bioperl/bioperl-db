
use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;    
    plan tests => 9;
}


use DBTestHarness;
use Bio::DB::SQL::DBAdaptor;


$harness = DBTestHarness->new();

ok $harness;


$db = $harness->get_DBAdaptor();

ok $db;

$fadp = $db->get_SeqFeatureAdaptor();

ok $fadp;

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


$fadp->store($feature,1,12);

$dbf = $fadp->fetch_by_dbID(1);

ok $feature;

ok ($feature->location->start  == $dbf->location->start);
ok ($feature->location->end    == $dbf->location->end);
ok ($feature->location->strand == $dbf->location->strand);

ok (scalar($feature->each_tag_value('tag12')) == 2);

($value) = $feature->each_tag_value('another-tag');

ok( $value eq 'something else');





