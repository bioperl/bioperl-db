use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;    
    plan tests => 22;
}

use DBTestHarness;
use Bio::DB::SQL::DBAdaptor;
use Bio::SeqIO;

$harness = DBTestHarness->new();


ok $harness;

$db_name = $harness->dbname; 

ok $db_name;


$db = $harness->get_DBAdaptor();

ok $db;

$dba = $db->get_BioDatabaseAdaptor; 

ok $dba; 

$seqio = Bio::SeqIO->new('-format' => 'GenBank',-file => 't/data/test.genbank');

ok $seqio;

$db_id = $dba->fetch_by_name_store_if_needed('sprot');

ok $db_id; 

$seqadaptor = $db->get_SeqAdaptor;

ok $seqadaptor;

$seq_detailed = $seqio->next_seq(); 
$acc = $seq_detailed->accession; 
$seqadaptor->store($db_id,$seq_detailed); 

ok ($acc); 

while ($seq = $seqio->next_seq()) {
	$dbID = $seqadaptor->store($db_id,$seq); 
}

ok ($dbID); 

# checking whether sequence can be deleted by dbID

$sth = $dba->prepare("select seqfeature_id from seqfeature br where br.bioentry_id=$dbID"); 
$sth->execute(); 
$seq_feature_ids = join ",",$sth->fetchrow_array(); 

ok ($seq_feature_ids); 

eval ("\$seqadaptor->remove_by_dbID($dbID)"); 
ok (!$@); 


#ok (!$@); 

#checking whether all sequence features are deleted correctly

$sth = $dba->prepare("select seqfeature_location_id from seqfeature_location br where br.seqfeature_id IN ($seq_feature_ids)"); 
$sth->execute(); 
@arr = $sth->fetchrow_array();  

ok (!@arr); 

$sth = $dba->prepare("select seqfeature_qualifier_id from seqfeature_qualifier_value br where br.seqfeature_id IN ($seq_feature_ids)"); 
$sth->execute(); 
@arr = $sth->fetchrow_array();  

ok (!@arr); 

$sth = $dba->prepare("select reference_id from bioentry_reference br where br.bioentry_id=$dbID"); 
$sth->execute(); 
@arr = $sth->fetchrow_array();  

ok (!@arr); 

$sth = $dba->prepare("select keywords from bioentry_keywords br where br.bioentry_id=$dbID"); 
$sth->execute(); 
@arr = $sth->fetchrow_array();  

ok (!@arr); 

$sth = $dba->prepare("select date from bioentry_date br where br.bioentry_id=$dbID"); 
$sth->execute(); 
@arr = $sth->fetchrow_array();  

ok (!@arr); 

$sth = $dba->prepare("select description from bioentry_description br where br.bioentry_id=$dbID"); 
$sth->execute(); 
@arr = $sth->fetchrow_array();  

ok (!@arr); 


$sth = $dba->prepare("select taxa_id from bioentry_taxa br where br.bioentry_id=$dbID"); 
$sth->execute(); 
@arr = $sth->fetchrow_array();  

ok (!@arr); 

$sth = $dba->prepare("select biosequence_id from biosequence br where br.bioentry_id=$dbID"); 
$sth->execute(); 
@arr = $sth->fetchrow_array();  

ok (!@arr); 

$sth = $dba->prepare("select seqfeature_id from seqfeature br where br.bioentry_id=$dbID"); 
$sth->execute(); 
@arr = $sth->fetchrow_array();  

ok (!@arr); 


eval ("\$seqadaptor->remove_by_db_and_accession('sprot',$acc)"); 

ok (!$@); 


eval( '$dba->remove_by_name("sprot")' );
 
ok (!$@); 
