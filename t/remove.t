# -*-Perl-*-
# $Id$

use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;    
    plan tests => 20;
}

use BioSQLBase;
use Bio::DB::SQL::DBAdaptor;
use Bio::SeqIO;

$biosql = BioSQLBase->new();
ok $biosql;

my $seqio = Bio::SeqIO->new('-format' => 'genbank',
			    '-file' => Bio::Root::IO->catfile('t','data',
							      'test.genbank'));

my $seq;
my @seqs = ();
my @arr = ();

eval {
    while($seq = $biosql->store_seq($seqio, "mytestnamespace")) {
	push(@seqs, $seq);
	ok $seq->primary_id();
    }
    ok (scalar(@seqs), 4);
    $seq = @seqs[$#seqs];

    $seqadaptor = $biosql->db()->get_SeqAdaptor;
    ok $seqadaptor;

    # features
    my $sfadp = $biosql->db()->get_SeqFeatureAdaptor();
    ok $sfadp;

    @arr = $sfadp->fetch_by_bioentry_id($seq->primary_id());
    ok (scalar(@arr), 26);

    # references
    my $rfadp = $biosql->db()->get_ReferenceAdaptor();
    ok $rfadp;

    @arr = $rfadp->fetch_by_bioentry_id($seq->primary_id());
    ok (scalar(@arr), 1);

    # qualifier/value
    @arr = $seqadaptor->each_tag_value_pair($seq->primary_id());
    ok (scalar(@arr), 2);

    # checking whether sequence can be deleted by dbID
    ok ($seqadaptor->remove_by_dbID($seq->primary_id()), 1);

    # should be no features anymore
    @arr = $sfadp->fetch_by_bioentry_id($seq->primary_id());
    ok (scalar(@arr), 0);

    # should be no references anymore
    @arr = $rfadp->fetch_by_bioentry_id($seq->primary_id());
    ok (scalar(@arr), 0);
    
    # should be no qualifier/values anymore
    @arr = $seqadaptor->each_tag_value($seq->primary_id());
    ok (scalar(@arr), 0);

#  $sth = $dba->prepare("select taxa_id from bioentry_taxa br where br.bioentry_id=$dbID"); 
#  $sth->execute(); 
#  @arr = $sth->fetchrow_array();  

#  ok (!@arr); 

#  $sth = $dba->prepare("select biosequence_id from biosequence br where br.bioentry_id=$dbID"); 
#  $sth->execute(); 
#  @arr = $sth->fetchrow_array();  

#  ok (!@arr); 

};

print STDERR $@ if $@;

# delete seqs
pop @seqs;
foreach $seq (@seqs) {
    ok ($biosql->delete_seq($seq), 1);
}
ok ($biosql->delete_biodatabase("mytestnamespace"), 1);

