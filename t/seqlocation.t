

use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;    
    plan tests => 10;
}


use DBTestHarness;
use Bio::DB::SQL::DBAdaptor;


$harness = DBTestHarness->new();

ok $harness;


$db = $harness->get_DBAdaptor();

ok $db;

$sadp = $db->get_SeqLocationAdaptor();

ok $sadp;


$location = Bio::Location::Simple->new();

$location->start(1);
$location->end(10);
$location->strand(-1);

$sadp->store($location,1);


ok $sadp;

$dbloc = $sadp->fetch_by_dbID(1);

ok ($location->start == $dbloc->start);

ok ($location->end == $dbloc->end);

ok ($location->strand == $dbloc->strand);


$loc2 = Bio::Location::Simple->new();

$loc2->start(20);
$loc2->end(30);
$loc2->strand(-1);


$split= Bio::Location::Split->new();

$split->add_sub_Location($location);
$split->add_sub_Location($loc2);

$sadp->store($split,2);

ok $split;

$dbsplit = $sadp->fetch_by_dbID(2);

ok ($dbsplit->isa('Bio::Location::SplitLocationI') );

ok (scalar($dbsplit->sub_Location) == 2 );



