#!/usr/local/lib/perl

use Bio::CorbaServer::BioEnv;
use Bio::CorbaClient::SeqDB;
use Bio::DB::CacheServer::SeqDB;
use Bio::DB::BioSQL::DBAdaptor;


use CORBA::ORBit idl => [ 'biocorba.idl' ];
use Getopt::Long;

my $host = "localhost";
my $sqlname = "bioperlcache";
my $dbuser = "root";
my $dbpass = undef;
my $format = 'fasta';
my $dbname = undef;

&GetOptions( 'host:s' => \$host,
	     'sqldb:s'  => \$sqlname,
	     'dbuser:s' => \$dbuser,
	     'dbpass:s' => \$dbpass,
	     'format:s' => \$format,
	     'dbname:s' => \$dbname,
	     'iorfile:s' => \$iorfile
	     );

if( !defined $dbname) {
    die "Must specify the dbname to cache\n";
}


# build the ORB

my $orb = CORBA::ORB_init("orbit-local-orb");
my $root_poa = $orb->resolve_initial_references("RootPOA");

# get the corba object of our remote server

open(F,"$iorfile") || die "Could not open $iorfile";
$ior = <F>;
chomp $ior;
close(F);

my $remote = $orb->string_to_object($ior);
my $corba_ref = $remote->get_SeqDB_by_name($dbname);

if( !defined $corba_ref ) {
    die "No remote database for $dbname";
}

# bind the corba object as Bioperl Client

my $read = Bio::CorbaClient::SeqDB->new( -corbaref => $corba_ref);


# connect to our local database. This will throw on inability to connect

$dbadaptor = Bio::DB::BioSQL::DBAdaptor->new( -host => $host,
					   -dbname => $sqlname,
					   -user => $dbuser,
					   -pass => $dbpass
					   );


# build a caching server 

my $cache = Bio::DB::CacheServer::SeqDB->new( -read_db => $read,
					      -write_dbadaptor => $dbadaptor,
					      -dbname => $dbname);


# bind cache to a servant object

my $servant = Bio::CorbaServer::BioEnv->new('-poa' => $root_poa, 
					 '-no_destroy' => 1);


$servant->add_SeqDB($dbname,"unknown-version",$cache);

# Read to rock and roll

# this registers this object as a live object with the ORB
my $id = $root_poa->activate_object ($servant);


# we need to get the IOR of this object. The way to do this is to
# to get a client of the object (temp) and then get the IOR of the
# client
$temp = $root_poa->id_to_reference ($id);
my $ior = $orb->object_to_string ($temp);

# write out the IOR. This is what we give to a different machine
$out_file = "cache.ior";
open (OUT, ">$out_file") || die "Cannot open file for ior: $!";
print OUT "$ior";
close OUT;

# tell everyone we are ready for it
print STDERR "Activating the ORB. IOR written to $out_file\n";

# and off we go. Woo Hoo!
$root_poa->_get_the_POAManager->activate;
$orb->run;

