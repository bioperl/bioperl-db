

use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;    
    plan tests => 3;
}

use DBTestHarness;
use Bio::DB::SQL::DBAdaptor;


$harness = DBTestHarness->new();

ok $harness;


$db = $harness->get_DBAdaptor();

ok $db;

$sth = $db->prepare("select now()");

$sth->execute;

ok $sth;


