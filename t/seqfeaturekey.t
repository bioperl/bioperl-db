
use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;    
    plan tests => 11;
}


use DBTestHarness;
use Bio::DB::SQL::DBAdaptor;


$harness = DBTestHarness->new();

ok $harness;


$db = $harness->get_DBAdaptor();

ok $db;


$sk = $db->get_SeqFeatureKeyAdaptor;

ok $sk; 

$id = $sk->store_if_needed("key12");

ok $id;

$id2 = $sk->store_if_needed("key12");

ok ( $id == $id2);


$sk = $db->get_SeqFeatureQualifierAdaptor;

ok $sk; 

$id = $sk->store_if_needed("key12");

ok $id;

$id2 = $sk->store_if_needed("key12");

ok ( $id == $id2);

$sk = $db->get_SeqFeatureSourceAdaptor;

ok $sk; 

$id = $sk->store_if_needed("key12");

ok $id;

$id2 = $sk->store_if_needed("key12");

ok ( $id == $id2);




