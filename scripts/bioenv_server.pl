#!/usr/local/lib/perl

use Bio::CorbaServer::BioEnv;
use CORBA::ORBit idl => [ 'biocorba.idl' ];
use Bio::DB::BioSQL::DBAdaptor;
use Getopt::Long;

my $host = "localhost";
my $sqlname = "bioperl";
my $dbuser = "root";
my $dbpass = undef;
my $format = 'fasta';

&GetOptions( 'host:s' => \$host,
	     'sqldb:s'  => \$sqlname,
	     'dbuser:s' => \$dbuser,
	     'dbpass:s' => \$dbpass,
	     'format:s' => \$format,
	     );

$dbadaptor = Bio::DB::BioSQL::DBAdaptor->new( -host => $host,
					   -dbname => $sqlname,
					   -user => $dbuser,
					   -pass => $dbpass
					   );



#build the actual orb and get the first POA (Portable Object Adaptor)
my $orb = CORBA::ORB_init("orbit-local-orb");
my $root_poa = $orb->resolve_initial_references("RootPOA");
my $servant = Bio::CorbaServer::BioEnv->new('-poa' => $root_poa, 
					 '-no_destroy' => 1);


$biodb = $dbadaptor->get_BioDatabaseAdaptor;

foreach $name ( $biodb->list_biodatabase_names ) {
    $bioseqdb = $biodb->fetch_BioSeqDatabase_by_name($name);
    $servant->add_SeqDB($name,"unknown-version",$bioseqdb);
}


# this registers this object as a live object with the ORB
my $id = $root_poa->activate_object ($servant);


# we need to get the IOR of this object. The way to do this is to
# to get a client of the object (temp) and then get the IOR of the
# client
$temp = $root_poa->id_to_reference ($id);
my $ior = $orb->object_to_string ($temp);

# write out the IOR. This is what we give to a different machine
$ior_file = "bioenv.ior";
open (OUT, ">$ior_file") || die "Cannot open file for ior: $!";
print OUT "$ior";
close OUT;

# tell everyone we are ready for it
print STDERR "Activating the ORB. IOR written to bioenv.ior\n";

# and off we go. Woo Hoo!
$root_poa->_get_the_POAManager->activate;
$orb->run;
