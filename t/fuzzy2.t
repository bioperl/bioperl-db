# -*-Perl-*-
# $Id$

use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;
    plan tests => 20;
}

# -----------------------------------------------
# REQUIREMENTS TESTED: (not yet!)
# unknown start/end (eg like we find in SP)
# must be handled gracefully
# cjm@fruitfly.org
# -----------------------------------------------

use BioSQLBase;
use Bio::DB::SQL::DBAdaptor;
use Bio::SeqIO;

$biosql = BioSQLBase->new();
ok $biosql;

$seq = $biosql->store_seq(Bio::SeqIO->new('-format' => 'embl',
					  '-file' => Bio::Root::IO->catfile(
					        't','data','AB030700.embl')),
					  "mytestnamespace");
ok $seq;
ok $seq->primary_id();

eval {
    $seqadaptor = $biosql->db()->get_SeqAdaptor;
    ok $seqadaptor;

    $dbseq = $seqadaptor->fetch_by_db_and_accession("mytestnamespace",
						    "AB030700");
    ok $dbseq;

    ok ($dbseq->display_id, $seq->display_id);
    ok ($dbseq->accession, $seq->accession);
    ok ($dbseq->seq, $seq->seq);
    ok ($dbseq->subseq(3,10), $seq->subseq(3,10) );
    ok ($dbseq->subseq(1,15), $seq->subseq(1,15) );
    ok ($dbseq->length, $seq->length);
    ok ($dbseq->length, length($dbseq->seq));

    my $test_desc = $seq->desc;
    $test_desc =~ s/\s+$//g;
    ok ($dbseq->desc, $test_desc);

    @dblinks = sort {
	$a->primary_id cmp $b->primary_id
	} $dbseq->annotation->get_Annotations('dblink');
    @stdlinks = sort {
	$a->primary_id cmp $b->primary_id
	} $seq->annotation->get_Annotations('dblink');

    ok (scalar(@dblinks));
    ok (scalar(@stdlinks));
    ok (scalar(@dblinks), scalar(@stdlinks));

    ok($dblinks[0]->optional_id, $stdlinks[0]->optional_id);

    $dl1 = shift @dblinks;
    $std1 = shift @stdlinks;
    ok ( $dl1->primary_id, $std1->primary_id);

    #$out = Bio::SeqIO->new( -file => '>t/tmp.embl' , -"format" => 'embl');
    #$out->write_seq($dbseq);

};

print STDERR $@ if $@;

# delete seq
ok ($biosql->delete_seq($seq), 1);
ok ($biosql->delete_biodatabase("mytestnamespace"), 1);

