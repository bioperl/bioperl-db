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

use DBTestHarness;
use Bio::DB::BioSQL::DBAdaptor;
use Bio::SeqIO;
use Bio::Root::IO;

$biosql = DBTestHarness->new("biosql");
$db = $biosql->get_DBAdaptor();
ok $db;
$db->verbose(1) if $ENV{HARNESS_VERBOSE};

my $seqio = Bio::SeqIO->new('-format' => 'genbank',
			    '-file' => Bio::Root::IO->catfile(
						  't','data','AP000868.gb'));
my $seq = $seqio->next_seq();
ok $seq;

my $pseq = $db->create_persistent($seq);
$pseq->namespace("mytestnamespace");
$pseq->store();
ok $pseq->primary_key();

my $seqadp = $db->get_object_adaptor($seq);

# try/finally block
eval {
    $dbseq = $seqadp->find_by_primary_key($pseq->primary_key());
    ok $dbseq;
    
    ok ($dbseq->display_id, $seq->display_id);
    ok ($dbseq->accession, $seq->accession);
    ok ($dbseq->subseq(3,10), $seq->subseq(3,10) );
    ok ($dbseq->subseq(1,15), $seq->subseq(1,15) );
    ok ($dbseq->length, $seq->length);
    ok ($dbseq->seq, $seq->seq);

    ok ($dbseq->desc, $seq->desc);

#$out = Bio::SeqIO->new('-file' => '>t/ensembl_test.gb' ,
#		       '-format' => 'GenBank');
#$out->write_seq($dbseq);
};

print STDERR $@ if $@;

# delete seq
ok ($pseq->remove(), 1);
my $ns = Bio::DB::Persistent::BioNamespace->new(-identifiable => $pseq);
ok $ns = $db->get_object_adaptor($ns)->find_by_unique_key($ns);
ok $ns->primary_key();
ok ($ns->remove(), 1);


