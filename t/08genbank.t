# -*-Perl-*-
# $Id$

use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;    
    plan tests => 18;
}


use DBTestHarness;
use Bio::SeqIO;
use Bio::Root::IO;
use Bio::DB::Persistent::BioNamespace;

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
$pseq->store();
ok $pseq->primary_key();

my $adp = $db->get_object_adaptor($seq);
ok $adp;

my $seqfact = Bio::Seq::SeqFactory->new(-type => "Bio::Seq::RichSeq");
ok $seqfact;

# try/finally block
eval {
    my $dbseq = $adp->find_by_primary_key($pseq->primary_key, $seqfact);
    ok $dbseq;

    ok ($dbseq->display_id, $seq->display_id);
    ok ($dbseq->accession_number, $seq->accession_number);
    ok ($dbseq->namespace, $seq->namespace);
    skip (! defined($seq->version), $dbseq->version, $seq->version);
    ok ($dbseq->seq_version, 1);
    ok ($dbseq->seq_version, $seq->seq_version);
    ok ($dbseq->version, 1);
    ok ($dbseq->version, $seq->version);
};

print STDERR $@ if $@;

# delete seq
ok ($pseq->remove(), 1);
my $ns = Bio::DB::Persistent::BioNamespace->new(-identifiable => $pseq);
ok $ns = $db->get_object_adaptor($ns)->find_by_unique_key($ns);
ok $ns->primary_key();
ok ($ns->remove(), 1);
