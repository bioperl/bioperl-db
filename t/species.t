# -*-Perl-*-
# $Id$

use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;    
    plan tests => 5;
}

use BioSQLBase;
use DBTestHarness;
use Bio::DB::BioSQL::DBAdaptor;

$biosql = BioSQLBase->new();
ok $biosql;

$sa = $biosql->db()->get_SpeciesAdaptor;
ok $sa;

$s = Bio::Species->new('-classification' => [qw(Eukaryota Metazoa Chordata
						Vertebrata Mammalia Eutheria
						Primates Catarrhini Hominidae
						Homo sapiens)]);
$dbid = $sa->store_if_needed($s);

$dbobj = $sa->fetch_by_dbID($dbid);

ok ($dbobj->species, $s->species);
ok ($dbobj->genus, $s->genus);

$db2   = $sa->store_if_needed($s);
ok ( $dbid, $db2 );

