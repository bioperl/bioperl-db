# -*-Perl-*-
# $Id$

use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;    
    plan tests => 15;
}
#END { unlink( 't/ensembl_test.gb') }

use BioSQLBase;
use Bio::DB::SQL::DBAdaptor;
use Bio::SeqIO;
use Bio::Root::IO;

$biosql = BioSQLBase->new();
ok $biosql;

$seq = $biosql->store_seq(Bio::SeqIO->new('-format' => 'genbank',
					  '-file' => Bio::Root::IO->catfile(
					       't','data','AP000868.gb')),
					  "mytestnamespace");
ok $seq;
ok $seq->primary_id();

$seqadaptor = $biosql->db()->get_SeqAdaptor;
ok $seqadaptor;

# try/finally block
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

#$out = Bio::SeqIO->new('-file' => '>t/ensembl_test.gb' ,
#		       '-format' => 'GenBank');
#$out->write_seq($dbseq);
};

print STDERR $@ if $@;

# delete seq
ok ($biosql->delete_seq($seq), 1);
ok ($biosql->delete_biodatabase("mytestnamespace"), 1);


