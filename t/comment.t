# -*-Perl-*-
# $Id$

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
use Bio::SeqIO;
use Bio::Root::IO;
use Bio::Annotation::Comment;

$biosql = DBTestHarness->new("biosql");
$db = $biosql->get_DBAdaptor();
ok $db;

my $seqio = Bio::SeqIO->new('-format' => 'genbank',
			    '-file' => Bio::Root::IO->catfile(
						      't','data','parkin.gb'));
my $seq = $seqio->next_seq();
ok $seq;
my $pseq = $db->create_persistent($seq);
$pseq->namespace("mytestnamespace");
# store seq
$pseq->create();
ok $pseq->primary_key();

$adp = $db->get_object_adaptor("Bio::Annotation::Comment");
ok $adp;

# start try/finally
eval {
    my $comment = Bio::Annotation::Comment->new();
    $comment->text("Some text");
    
    my $pcomment = $adp->create_persistent($comment);
    $pcomment->rank(10);
    $pcomment->create(-fkobjs => [$pseq]);
    ok $pcomment->primary_key();

    my $dbcomment = $adp->find_by_primary_key($pcomment->primary_key());
    
    ok $dbcomment;
    
    ok ($dbcomment->text, $comment->text);
};

print STDERR $@ if $@;

# delete seq
ok ($pseq->remove(), 1);
my $ns = Bio::DB::Persistent::BioNamespace->new(-identifiable => $pseq);
ok $ns = $db->get_object_adaptor($ns)->find_by_unique_key($ns);
ok $ns->primary_key();
ok ($ns->remove(), 1);
