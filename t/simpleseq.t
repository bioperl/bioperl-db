# -*-Perl-*-
# $Id$

use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;    
    plan tests => 21;
}

use BioSQLBase;
use Bio::DB::SQL::DBAdaptor;
use Bio::SeqIO;
use Bio::Root::IO;

$biosql = BioSQLBase->new();
ok $biosql;

$seq = $biosql->store_seq(Bio::SeqIO->new('-format' => 'genbank',
					  '-file' => Bio::Root::IO->catfile(
						      't','data','parkin.gb')),
			  "mytestnamespace");

ok $seq;
ok $seq->primary_id();

$seqadaptor = $biosql->db()->get_SeqAdaptor;
ok $seqadaptor;

# start try/finally
eval {
    $dbseq = $seqadaptor->fetch_by_dbID($seq->primary_id());
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

    $dbseq = $seqadaptor->fetch_by_db_and_accession("mytestnamespace",
						    $seq->accession);
    ok $dbseq;

    $desc = $seqadaptor->get_description_by_accession($seq->accession);
    ok $desc;

    my ($cds) = grep { $_->primary_tag() eq 'CDS' } $dbseq->top_SeqFeatures();
    ok $cds;
    ok ($cds->start, 71 );
    ok ($cds->end, 1465 );

    ($dbxref) = $cds->each_tag_value('db_xref');
    ok ($dbxref, 'GI:5456930');
};

print STDERR $@ if $@;

# delete seq
ok ($biosql->delete_seq($seq), 1);
ok ($biosql->delete_biodatabase("mytestnamespace"), 1);
