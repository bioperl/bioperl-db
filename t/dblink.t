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
$db->verbose(1) if $ENV{HARNESS_VERBOSE};

my $seqio = Bio::SeqIO->new('-format' => 'genbank',
			    '-file' => Bio::Root::IO->catfile(
						      't','data','parkin.gb'));
my $seq = $seqio->next_seq();
ok $seq;
my $pseq = $db->create_persistent($seq);
$pseq->namespace("mytestnamespace");
$pseq->store();
ok $pseq->primary_key();

my $dbl = Bio::Annotation::DBLink->new();
$dbl->database("new-db");
$dbl->primary_id("primary-id-12");

# try/finally block
eval {
    my $pdbl = $db->create_persistent($dbl);
    $pdbl->store();
    ok $pdbl->primary_key();
    
    my $dbladp = $db->get_object_adaptor("Bio::Annotation::DBLink");
    my $fromdb = $dbladp->find_by_primary_key($pdbl->primary_key());
    ok $fromdb;
    ok ($fromdb->primary_key, $pdbl->primary_key);
    ok ($fromdb->database, $dbl->database);
    ok ($fromdb->primary_id, $dbl->primary_id);

    ok $dbladp->add_association(-objs => [$pseq, $pdbl]);

    my $dbseq = $pseq->adaptor()->find_by_primary_key($pseq->primary_key());
    ok $dbseq;
    my @mydbls = grep {
	$_->database() eq "new-db";
    } $dbseq->annotation->get_Annotations("dblink");
    ok (scalar(@mydbls), 1);
    ok ($mydbls[0]->primary_id, $dbl->primary_id);
    ok ($mydbls[0]->primary_key, $pdbl->primary_key);

    ok ($fromdb->remove(), 1);
};

print STDERR $@ if $@;

# delete seq
ok ($pseq->remove(), 1);
my $ns = Bio::DB::Persistent::BioNamespace->new(-identifiable => $pseq);
ok $ns = $db->get_object_adaptor($ns)->find_by_unique_key($ns);
ok $ns->primary_key();
ok ($ns->remove(), 1);

