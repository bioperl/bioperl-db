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

$sk = $biosql->db()->get_SeqFeatureSourceAdaptor();
ok $sk;

$id = $sk->store_if_needed("key12");
ok $id;

# try/finally
eval {
    $id2 = $sk->store_if_needed("key12");
    ok ( $id, $id2);
};

print STDERR $@ if $@;

ok ($sk->remove_by_dbID($id, $id2), 1);
