# -*-Perl-*-
# $Id$

use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;
    plan tests => 66;
}

use DBTestHarness;
use Bio::ClusterIO;
use Bio::Root::IO;

$biosql = DBTestHarness->new("biosql");
$db = $biosql->get_DBAdaptor();
ok $db;
$db->verbose(1) if $ENV{HARNESS_VERBOSE};

my $objio = Bio::ClusterIO->new('-format' => 'unigene',
				'-file' => Bio::Root::IO->catfile(
					         't','data','unigene.data'));
my $clu = $objio->next_cluster();
ok $clu;

my $pclu = $db->create_persistent($clu);
ok $pclu;
ok $pclu->isa("Bio::DB::PersistentObjectI");
ok $pclu->isa("Bio::ClusterI");

$pclu->namespace("mytestnamespace");
$pclu->store();
my $dbid = $pclu->primary_key();
ok $dbid;

my $adp = $db->get_object_adaptor($clu);
ok $adp;
ok $adp->isa("Bio::DB::PersistenceAdaptorI");

# try/finally
eval {
    $dbclu = $adp->find_by_primary_key($dbid);
    ok $dbclu;

    ok ($dbclu->display_id, $clu->display_id);
    ok ($dbclu->description, $clu->description);
    ok ($dbclu->size, $clu->size);
    ok (scalar($dbclu->get_members), scalar($clu->get_members));
    ok (scalar($dbclu->get_members), $clu->size);
    ok ($dbclu->species->binomial, $clu->species->binomial);

    # check all annotation objects
    my @dbkeys =
	sort { $a cmp $b } $dbclu->annotation->get_all_annotation_keys();
    my @keys =
	sort { $a cmp $b } $clu->annotation->get_all_annotation_keys();
    ok (scalar(@dbkeys), scalar(@keys));
    my $i = 0;
    while($i < @dbkeys) {
	ok ($dbkeys[$i], $keys[$i]);
	my @dbanns = sort {
	    $a->as_text cmp $b->as_text;
	} $dbclu->annotation->get_Annotations($dbkeys[$i]);
	my @anns = sort {
	    $a->as_text cmp $b->as_text;
	} $clu->annotation->get_Annotations($keys[$i]);
	ok (scalar(@dbanns), scalar(@anns),
	    "number of annotations don't match for key ".$dbkeys[$i].
	    ": got ".scalar(@dbanns).", expected ".scalar(@anns));
	my $j = 0;
	while($j < @dbanns) {
	    ok ($dbanns[$j]->as_text, $anns[$j]->as_text,
		"values for annotation element $j don't match for key ".
		$dbkeys[$i].
		": got \"".$dbanns[$j]->as_text.
		"\", expected \"".$anns[$j]->as_text."\"");
	    $j++;
	}
	$i++;
    }

    # check all members
    my @dbmems = sort {
	$a->accession_number() cmp $b->accession_number();
    } $dbclu->get_members();
    my @mems = sort {
	$a->accession_number() cmp $b->accession_number();
    } $clu->get_members();
    $i = 0;
    while(($i < @mems) && ($i < @dbmems)) {
	ok ($dbmems[$i]->accession_number, $mems[$i]->accession_number);
	$i++;
    }
};

print STDERR $@ if $@;

# delete clu
ok ($pclu->remove(), 1);
my $ns = Bio::DB::Persistent::BioNamespace->new(-identifiable => $pclu);
ok $ns = $db->get_object_adaptor($ns)->find_by_unique_key($ns);
ok $ns->primary_key();
ok ($ns->remove(), 1);
