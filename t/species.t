
use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;    
    plan tests => 6;
}


use DBTestHarness;
use Bio::DB::SQL::DBAdaptor;


$harness = DBTestHarness->new();

ok $harness;


$db = $harness->get_DBAdaptor();

ok $db;


$sa = $db->get_SpeciesAdaptor;

ok $sa;

$s = Bio::Species->new(-classification => [qw(Eukaryota Metazoa Chordata Vertebrata Mammalia Eutheria Primates Catarrhini Hominidae Homo sapiens)]);

$dbid = $sa->store_if_needed($s);

$dbobj = $sa->fetch_by_dbID($dbid);

ok ($dbobj->species eq $s->species);
ok ($dbobj->genus   eq $s->genus);

$db2   = $sa->store_if_needed($s);

ok ( $dbid == $db2 );