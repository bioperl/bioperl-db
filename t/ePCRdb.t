# -*-Perl-*-

use strict;
use lib 't';

BEGIN {     
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;
    plan test => 3;
}


use DBTestHarness;
use Bio::DB::Map::SQL::DBAdaptor;
use Bio::DB::Map::Marker;
use Bio::DB::Map::Map;
use Bio::Root::IO;

my $harness = DBTestHarness->new('markerdb');

ok($harness);

my $db = $harness->get_DBAdaptor();

ok ($db);
my $mapadaptor = $db->get_MapAdaptor();

ok ($mapadaptor);
#my $map = $mapadaptor->get('-name' => 'marshfield');

#my $markeradaptor = $db->get_MarkerAdaptor();

#my $marker = new Bio::DB::Map::Marker( -locus => 'D1S243',
	#			       -probe => 'AFM214yg7',
	#			       -length=> 201,
	#			       -pcrfwd=> 'CACACAGGCTCACATGCC',
	#			       -pcrrev=> 'GCTCCAGCGTCATGGACT',
	#			       -type  => 'ms',
	#			       -chrom => 'chr1' );
				
#$marker->add_position('3.01', 'marshfield');
#$markeradaptor->write($marker);
#ok($marker->id);

#my $io = new Bio::Root::IO();
#my ($handle,$file) = $io->tempfile();

#$mapadaptor->create_ePCR_DB($map->id, $handle);

#close($handle);
#open(IN, $file) or die("cannot open file $file");
#while(<IN>) {
#    ok($_);
#}
#close IN;
