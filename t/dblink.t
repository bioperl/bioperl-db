# -*-Perl-*-
# $Id$

use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;    
    plan tests => 12;
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

$adp = $biosql->db()->get_DBLinkAdaptor();
ok $adp;

my $dbl = Bio::Annotation::DBLink->new();
$dbl->database("new-db");
$dbl->primary_id("primary-id-12");

# try/finally block
eval {
    my $pk = $adp->store($dbl, $seq->primary_id());
    ok $pk;
    
    $fromdb = $adp->fetch_by_dbID($pk);
    
    ok $fromdb;
    
    ok ($fromdb->database eq $dbl->database);
    
    ok ($fromdb->primary_id eq $dbl->primary_id);

    ok ($adp->remove_by_bioentry_id($seq->primary_id()), 1);
    ok ($biosql->db()->get_DBXrefAdaptor()->remove($dbl), 1);
};

print STDERR $@ if $@;

# delete seq
ok ($biosql->delete_seq($seq), 1);
ok ($biosql->delete_biodatabase("mytestnamespace"), 1);

