# -*-Perl-*-

use strict;
use lib 't';

BEGIN {     
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;
    plan test => 10;
}


use DBTestHarness;
use Bio::DB::Map::SQL::DBAdaptor;
use Bio::DB::Map::Marker;
use Bio::DB::Map::Map;

my $harness = DBTestHarness->new('markerdb');

ok($harness);

my $db = $harness->get_DBAdaptor();

ok ($db);
my $mapadaptor = $db->get_MapAdaptor();

ok ($mapadaptor);

my $map = $mapadaptor->get_Map('-name' => 'marshfield');

ok ($map);
ok ($map->name, 'marshfield');
ok ($map->units, 'cM');
ok ($map->chrom_length('chr1'), 0);

my $marker = new Bio::DB::Map::Marker( -locus => 'D1S243',
				       -probe => 'AFM214yg7',
				       -length=> 201,
				       -pcrfwd=> 'CACACAGGCTCACATGCC',
				       -pcrrev=> 'GCTCCAGCGTCATGGACT',
				       -type  => 'ms',
				       -chrom => 'chr1' );
				
$marker->add_position('3.01', 'marshfield');

ok ($marker);

my $markeradaptor = $db->get_MarkerAdaptor();
$markeradaptor->write($marker);       

ok ($marker->id);
ok ($map->chrom_length(1) == 3.01);
