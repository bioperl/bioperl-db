# -*-Perl-*-
# $Id$

use lib 't';

use vars qw($old_obda_path);

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;    
    plan tests => 12;

	 $old_obda_path = $ENV{OBDA_SEARCH_PATH} 
		if defined $ENV{OBDA_SEARCH_PATH};
	 $ENV{OBDA_SEARCH_PATH} = 't/data/';
}

use strict;
use DBTestHarness;
use Bio::SeqIO;
use Bio::Root::IO;
use Bio::DB::Persistent::BioNamespace;
use Bio::DB::Registry;

my $biosql = DBTestHarness->new("biosql");
my $db = $biosql->get_DBAdaptor();
ok $db;

my $registry_file = "t/data/seqdatabase.ini";
my $obda_name = "mytestbiosql";
# create a temporary seqdatabase.ini file specific for this test database
write_registry($registry_file);

my $seqio = Bio::SeqIO->new('-format' => 'genbank',
			    '-file' => Bio::Root::IO->catfile(
						      't','data','parkin.gb'));
my $seq = $seqio->next_seq();
ok $seq;
my $pseq = $db->create_persistent($seq);
$pseq->namespace("mytestnamespace");
$pseq->store(); # this will raise warnings if there are duplicates
ok $pseq->primary_key();
$pseq->commit;

# try/finally block
eval {
	my $registry = Bio::DB::Registry->new;
	ok $registry;
	my $biodb = $registry->get_database($obda_name);
	ok $biodb;
	my $seq = $biodb->get_Seq_by_acc('AB019558');
	ok $seq->primary_id, 5456929;
	$seq = $biodb->get_Seq_by_id(5456929);
	ok $seq->accession, "AB019558";
	$seq = $biodb->get_Seq_by_version('AB019558.1');
	ok $seq->primary_id, 5456929;
};

print STDERR $@ if $@;

# delete seq
ok ($pseq->remove(), 1);
my $ns = Bio::DB::Persistent::BioNamespace->new(-identifiable => $pseq);
ok $ns = $db->get_object_adaptor($ns)->find_by_unique_key($ns);
ok $ns->primary_key();
ok ($ns->remove(), 1);

END {
	unlink $registry_file if (-e $registry_file);
	$ENV{OBDA_SEARCH_PATH} = $old_obda_path if defined $old_obda_path;
}

sub write_registry {
	my $file = shift;
	my $c = $db->dbcontext;
	my ($host,$port,$dbname,$pass,$user,$driver) =
	 ($c->host,$c->port,$c->dbname,$c->password,$c->username,$c->driver);

	my $text = "VERSION=1.00

[$obda_name]
protocol=biosql
location=$host:$port
dbname=$dbname
passwd=$pass
user=$user
driver=$driver
";
   open F,">$file";
	print F $text;
   close F;
}
