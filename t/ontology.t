# -*-Perl-*-
# $Id$

use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;    
    plan tests => 291;
}

use DBTestHarness;
use Bio::OntologyIO;
use Bio::Root::IO;

$biosql = DBTestHarness->new("biosql");
ok $biosql;

$db = $biosql->get_DBAdaptor();
ok $db;
$db->verbose(1) if $ENV{HARNESS_VERBOSE};

my $io = Bio::Root::IO->new(); # saves typing
my $ontio = Bio::OntologyIO->new(-file => $io->catfile('t','data',
						       'sofa.ontology'),
				 -format => 'so');
ok ($ontio);
my $ont = $ontio->next_ontology();
ok ($ont);
$ont->name("My Test Ontology"); # avoid clashes

# insert by inserting all relationships (there are no isolated terms in SOFA)
foreach my $rel ($ont->get_relationships()) {
    # change ID prefix to avoid clashes
    foreach my $term_meth ("subject_term","object_term") {
	my $id = $rel->$term_meth->identifier();
	next if $id =~ /^MYTO/;
	$rel->$term_meth->identifier("MYTO:".substr($id,3)) if $id;
    }
    # make persistent and insert
    my $prel = $db->create_persistent($rel);
    ok ($prel->create());
    ok ($prel->primary_key());
}

# now get the ontology back from the database
my $dbont = Bio::Ontology::Ontology->new(-name => "My Test Ontology");
$dbont = $db->get_object_adaptor($dbont)->find_by_unique_key($dbont);
ok ($dbont);
ok ($dbont->primary_key());

# set up the query to get all relationships
my $query = Bio::DB::Query::BioQuery->new(
       -datacollections => ["Bio::Ontology::OntologyI=>Bio::Ontology::RelationshipI"],
       -where => ["Bio::Ontology::OntologyI::primary_key = ".
		  $dbont->primary_key()
		  ]
					  );
my $reladp = $db->get_object_adaptor("Bio::Ontology::RelationshipI");
my $qres = $reladp->find_by_query($query);
while(my $rel = $qres->next_object()) {
    ok ($rel->ontology->name, "My Test Ontology");
    $dbont->add_term($rel->subject_term);
    $dbont->add_term($rel->object_term);
    #$dbont->add_term($rel->predicate_term);
    $dbont->add_relationship($rel);
}

# now query the ontology
my ($term) = $dbont->find_terms(-identifier => "MYTO:0000233");
ok ($term);
ok ($term->identifier, "MYTO:0000233");
ok ($term->name, "processed_transcript");
@rels = $dbont->get_relationships($term);
ok (scalar(@rels), 5);
@relset = grep { $_->predicate_term->name eq "IS_A"; } @rels;
ok (scalar(@relset), 3);
@relset = grep { $_->object_term->identifier eq "MYTO:0000233"; } @rels;
ok (scalar(@relset), 4);

# check for correct storage and retrieval of synonyms and dbxrefs
($term) = $dbont->find_terms(-identifier => "MYTO:0000203");
ok ($term);
ok ($term->name, "untranslated_region");
my @syns = $term->get_synonyms();
ok (scalar(@syns), 1);
ok ($syns[0], "UTR");
# modify, update, and re-retrieve to check with multiple synonyms, and with
# dbxrefs (this version of SOFA doesn't come with any dbxrefs)
$term->add_synonym("junk DNA");
$term->add_dblink(Bio::Annotation::DBLink->new(-database   => "MYDB",
					       -primary_id => "yaddayadda"));
ok ($term->store());
$term = $term->adaptor->find_by_primary_key($term->primary_key);
ok ($term);
# now test
@syns = $term->get_synonyms();
ok (scalar(@syns), 2);
ok (scalar(grep { $_ eq "junk DNA"; } @syns), 1);
ok (scalar($term->get_dblinks()), 1);

#
# test the transitive closure computations
#
my $ontadp = $db->get_object_adaptor("Bio::Ontology::OntologyI");
my $ontname = "My BioSQL Predicate Ontology";
my $id_pred = Bio::Ontology::Term->new(-name => "identity",
				       -ontology => $ontname);
my $superpred = Bio::Ontology::Term->new(-name => "PART_OF",
					 -ontology => $ontname);
my $subcl_pred = Bio::Ontology::Term->new(-name => "implies",
					  -ontology => $ontname);

ok ($ontadp->compute_transitive_closure($ont,
					-truncate => 1,
					-predicate_superclass => $superpred,
					-subclass_predicate   => $subcl_pred,
					-identity_predicate   => $id_pred));
#
# now query and test the results
# set up the query to get all relationships
$query = Bio::DB::Query::BioQuery->new(
               -datacollections => ["Bio::Ontology::OntologyI=>Bio::Ontology::PathI o",
				    "Bio::Ontology::TermI=>Bio::Ontology::PathI tsubj::subject",
				    "Bio::Ontology::TermI=>Bio::Ontology::PathI tobj::object",
			 ],
	       -where => ["o.name = 'My Test Ontology'",
			  "tobj.name = 'gene'",
			  "tsubj.name = 'exon'"]
				       );
my $pathadp = $db->get_object_adaptor("Bio::Ontology::PathI");
$qres = $pathadp->find_by_query($query);
my $n = 0;
while(my $path = $qres->next_object()) {
    ok ($path->ontology->name, "My Test Ontology");
    ok ($path->subject_term->name, "exon");
    ok ($path->object_term->name, "gene");
    ok ($path->predicate_term->name, "PART_OF");
    $n++;
}
ok ($n, 1);
