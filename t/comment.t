

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

$adp = $db->get_CommentAdaptor();

ok $adp;

my $comment = Bio::Annotation::Comment->new();
$comment->text("Some text");

$adp->store($comment,1,12);

ok 1;

$dbcomment = $adp->fetch_by_dbID(1);

ok $dbcomment;

ok ($dbcomment->text eq $comment->text);