

use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;    
    plan tests => 7;
}


use DBTestHarness;
use Bio::DB::SQL::DBAdaptor;


$harness = DBTestHarness->new();

ok $harness;


$db = $harness->get_DBAdaptor();

ok $db;

$adp = $db->get_DBLinkAdaptor();

ok $adp;

my $dbl = Bio::Annotation::DBLink->new();

$dbl->database("new-db");
$dbl->primary_id("primary-id-12");


$adp->store($dbl,12);

ok 1;

$fromdb = $adp->fetch_by_dbID(1);

ok $fromdb;

ok ($fromdb->database eq $dbl->database);

ok ($fromdb->primary_id eq $dbl->primary_id);
