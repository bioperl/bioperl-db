# -*-Perl-*-
# $Id$

use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;    
    plan tests => 9;
}


use BioSQLBase;
use Bio::DB::SQL::DBAdaptor;
use Bio::SeqIO;

$biosql = BioSQLBase->new();
ok $biosql;

$seq = $biosql->store_seq(Bio::SeqIO->new('-format' => 'genbank',
					  '-file' => Bio::Root::IO->catfile(
						      't','data','parkin.gb')),
					  "mytestnamespace");

ok $seq;
ok $seq->primary_id();

eval {
    $adp = $biosql->db()->get_CommentAdaptor();
    ok $adp;

    my $comment = Bio::Annotation::Comment->new();
    $comment->text("Some text");
    
    ok defined($adp->store($comment, 1, $seq->primary_id()));

    ($dbcomment) = $adp->fetch_by_bioentry_id($seq->primary_id(), 1);
    
    ok $dbcomment;
    
    ok ($dbcomment->text, $comment->text);
};

print STDERR $@ if $@;

# delete seq
ok ($biosql->delete_seq($seq), 1);
ok ($biosql->delete_biodatabase("mytestnamespace"), 1);


