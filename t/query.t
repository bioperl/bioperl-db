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

use Bio::DB::Query::SqlQuery;
use Bio::DB::Query::SqlGenerator;
use Bio::DB::Query::BioQuery;
use Bio::DB::Query::QueryConstraint;
use Bio::DB::BioSQL::mysql::BasePersistenceAdaptorDriver;

my $query = Bio::DB::Query::SqlQuery->new(-tables => ["table1"]);
my $sqlgen = Bio::DB::Query::SqlGenerator->new(-query => $query);

my $sql = $sqlgen->generate_sql();
ok ($sql, "SELECT * FROM table1");

$query->add_datacollection("table1", "table2");
$sql = $sqlgen->generate_sql();
ok ($sql, "SELECT * FROM table1, table2");

$query->selectelts("col1", "col2", "col3");
$sql = $sqlgen->generate_sql();
ok ($sql, "SELECT col1, col2, col3 FROM table1, table2");

$query->groupelts("col1", "col3");
$sql = $sqlgen->generate_sql();
ok ($sql, "SELECT col1, col2, col3 FROM table1, table2 GROUP BY col1, col3");

$query->groupelts([]);
$query->orderelts("col2","col3");
$sql = $sqlgen->generate_sql();
ok ($sql, "SELECT col1, col2, col3 FROM table1, table2 ORDER BY col2, col3");

$query->where(["col4 = ?", "col5 = 'somevalue'"]);
$sql = $sqlgen->generate_sql();
ok ($sql, "SELECT col1, col2, col3 FROM table1, table2 WHERE col4 = ? AND col5 = 'somevalue' ORDER BY col2, col3");

$query->where(["and",
	       ["or", "col4 = ?", "col5 = 'somevalue'"],
	       ["col2 = col4", "col6 not like 'abcd*'"]]);
$sql = $sqlgen->generate_sql();
ok ($sql, "SELECT col1, col2, col3 FROM table1, table2 WHERE (col4 = ? OR col5 = 'somevalue') AND (col2 = col4 AND col6 NOT LIKE 'abcd\%') ORDER BY col2, col3");

$query = Bio::DB::Query::BioQuery->new();
$mapper = Bio::DB::BioSQL::mysql::BasePersistenceAdaptorDriver->new();

$query->selectelts(["accession_number","version"]);
$query->datacollections(["Bio::PrimarySeqI"]);
$tquery = $query->translate_query($mapper);
$sql = $sqlgen->generate_sql($tquery);
ok ($sql, "SELECT bioentry.accession, bioentry.entry_version FROM bioentry");

$query->selectelts([]);
$query->datacollections(["Bio::Species=>Bio::PrimarySeqI"]);
$tquery = $query->translate_query($mapper);
$sql = $sqlgen->generate_sql($tquery);
ok ($sql, "SELECT * FROM bioentry, taxon WHERE bioentry.taxon_id = taxon.taxon_id");

$query->datacollections(["Bio::PrimarySeqI e",
			 "Bio::Species=>Bio::PrimarySeqI sp"]);
$tquery = $query->translate_query($mapper);
$sql = $sqlgen->generate_sql($tquery);
ok ($sql, "SELECT * FROM bioentry e, taxon sp WHERE e.taxon_id = sp.taxon_id");

$query->datacollections(["Bio::PrimarySeqI e",
			 "Bio::Species=>Bio::PrimarySeqI sp",
			 "BioNamespace=>Bio::PrimarySeqI db"]);
$query->where(["sp.binomial like 'Mus *'",
	       "e.desc like '*receptor*'",
	       "db.namespace = 'ensembl'"]);
$tquery = $query->translate_query($mapper);
$sql = $sqlgen->generate_sql($tquery);
ok ($sql,
    "SELECT * ".
    "FROM bioentry e, taxon sp, biodatabase db ".
    "WHERE e.taxon_id = sp.taxon_id AND e.biodatabase_id = db.biodatabase_id ".
    "AND (sp.binomial LIKE 'Mus \%' AND e.description LIKE '\%receptor\%' ".
    "AND db.name = 'ensembl')");

$query->selectelts(["e.accession_number","e.version"]);
$query->datacollections(["Bio::PrimarySeqI e",
			 "Bio::Species=>Bio::PrimarySeqI sp",
			 "BioNamespace=>Bio::PrimarySeqI db",
			 "Bio::Annotation::DBLink xref",
			 "Bio::PrimarySeqI<=>Bio::Annotation::DBLink"]);
$query->where(["sp.binomial like 'Mus *'",
	       "e.desc like '*receptor*'",
	       "db.namespace = 'ensembl'",
	       "xref.database = 'SWISS'"]);
$query->flag();
$tquery = $query->translate_query($mapper);
$sql = $sqlgen->generate_sql($tquery);
ok ($sql,
    "SELECT e.accession, e.entry_version ".
    "FROM bioentry e, taxon sp, biodatabase db, dbxref xref, bioentry_dblink ".
    "WHERE e.taxon_id = sp.taxon_id AND e.biodatabase_id = db.biodatabase_id ".
    "AND e.bioentry_id = bioentry_dblink.bioentry_id ".
    "AND xref.dbxref_id = bioentry_dblink.dbxref_id ".
    "AND (sp.binomial LIKE 'Mus \%' AND e.description LIKE '\%receptor\%' ".
    "AND db.name = 'ensembl' AND xref.dbname = 'SWISS')");
