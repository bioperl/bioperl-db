# -*-Perl-*-

use strict;
use lib 't';

BEGIN {     
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;
    plan test => 6;
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

my $map = $mapadaptor->get('-name' => 'marshfield');

ok ($map);
ok ($map->name, 'marshfield');
#ok ($map->units, 'cM');
#ok ($map->chrom_length('chr1'), 0);

my $marker = new Bio::DB::Map::Marker( '-locus'  => 'D1S468',
				       '-probe'  => 'AFM280we5',
				       '-length' => 185,
				       '-pcrfwd' => 'AATTAACCGTTTTGGTCCT',
				       '-pcrrev' => 'GCGACACACACTTCCC',
				       '-type'  => 'ms',
				       '-chrom' => 'chr1' );

$marker->add_position('4.22', 'marshfield');

ok ($marker);
#my @mkrs;
#my $markeradaptor = $db->get_MarkerAdaptor();
#$markeradaptor->write($marker);       

#ok ($marker->id);

#push( @mkrs, $marker);

#ok ($map->chrom_length(1) == 4.22);

#$marker = new Bio::DB::Map::Marker( '-locus'  => 'D1S243',
#				    '-probe'  => 'AFM214yg7',
#				    '-length' => 201,
#				    '-pcrfwd' => 'CACACAGGCTCACATGCC',
#				    '-pcrrev' => 'GCTCCAGCGTCATGGACT',
#				    '-type'   => 'ms',
#				    '-chrom'  => 'chr1' );

#$marker->add_position('0.00', 'marshfield');
#$markeradaptor->write($marker);
#push( @mkrs, $marker);


#$marker = new Bio::DB::Map::Marker( '-locus'  => 'D1S2845',
#				    '-probe'  => 'AFM344we9',
#				    '-length' => 171,
#				    '-pcrfwd' => 'CCAAAGGGTGCTTCTC',
#				    '-pcrrev' => 'GTGGCATTCCAACCTC',
#				    '-type'   => 'ms',
#				    '-chrom'  => 'chr1' );
#$marker->add_position('8.85', 'marshfield');
#$markeradaptor->write($marker);
#push( @mkrs, $marker);
				
#ok ($map->chrom_length(1) == 8.85);

# test get_next_marker method

# test the map object
#my @markers = $map->get_next_marker('-marker'    => splice( @mkrs, 1,1),
#				    '-direction' => 1,
#				    '-number'    => 2);
#ok( @markers, @mkrs);

#while( @markers && @mkrs) {
#    ok( (shift @mkrs)->id, (shift @markers)->id );
#}

# test the get_markers_for_region

#@markers = $map->get_markers_for_region('-chrom' => 1,
#					'-start' => '0.00',
#					'-end'   => '8.00' );
#ok (@markers, 2);
