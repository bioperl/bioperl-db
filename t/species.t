# -*-Perl-*-
# $Id$

use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;    
    plan tests => 63;
}

use DBTestHarness;
use Bio::Species;

$biosql = DBTestHarness->new("biosql");
ok $biosql;

$db = $biosql->get_DBAdaptor();
ok $db;
$db->verbose(1) if $ENV{HARNESS_VERBOSE};

$s = Bio::Species->new('-classification' => [reverse(
					     qw(Eukaryota Metazoa Chordata
						Vertebrata Mammalia Eutheria
						Primates Catarrhini Hominidae
						Homo sapiens))]);
$p_s = $db->create_persistent($s);
ok $p_s;
ok $p_s->isa("Bio::DB::PersistentObjectI");
ok $p_s->isa("Bio::Species");

$p_s->create();
$dbid = $p_s->primary_key();
ok $dbid;

$adp = $db->get_object_adaptor($s);
ok $adp;
ok $adp->isa("Bio::DB::PersistenceAdaptorI");
$dbobj = $adp->find_by_primary_key($dbid);

ok ($dbobj->species, $s->species);
ok ($dbobj->genus, $s->genus);
ok (scalar($dbobj->classification), scalar($s->classification));
my @dbclf = $dbobj->classification();
my @clf = $s->classification();
while(@dbclf || @clf) {
    ok (shift(@dbclf), shift(@clf));
}

$dbobj2 = $adp->find_by_unique_key($s);
ok $dbobj2;
if($dbobj2) {
    ok ($dbobj2->primary_key(), $dbobj->primary_key());
    ok ($dbobj2->species, $s->species);
    ok ($dbobj2->genus, $s->genus);
    ok ($dbobj2->binomial, $s->binomial);
    ok (scalar($dbobj2->classification), scalar($s->classification));
    @dbclf = $dbobj->classification();
    @clf = $s->classification();
    while(@dbclf || @clf) {
	ok (shift(@dbclf), shift(@clf));
    }
} else {
    for (1..5) { skip("fetch by UK failed", 0); }
}

# delete and re-insert with NCBI taxon ID

ok ($p_s->remove(), 1);
$p_s->ncbi_taxid(9606);
ok ($p_s->create());
$dbobj2 = $adp->find_by_unique_key($s);
ok $dbobj2;
ok $dbobj2->primary_key;
ok (! ($dbobj2->primary_key == $dbobj->primary_key));
if($dbobj2) {
    ok ($dbobj2->species, $s->species);
    ok ($dbobj2->genus, $s->genus);
    ok ($dbobj2->binomial, $s->binomial);
    ok ($dbobj2->ncbi_taxid, $s->ncbi_taxid);
    ok (scalar($dbobj2->classification), scalar($s->classification));
    @dbclf = $dbobj->classification();
    @clf = $s->classification();
    while(@dbclf || @clf) {
	ok (shift(@dbclf), shift(@clf));
    }
} else {
    for (1..6) { skip("fetch by UK failed", 0); }
}

ok ($p_s->remove(), 1);
ok (undef, $p_s->primary_key());

$dbobj2 = $adp->find_by_unique_key($s);
ok (undef, $dbobj2);
