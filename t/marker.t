# -*-Perl-*- mode

use strict;
use lib 't';

BEGIN {     
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;
    plan test => 19;
}


use DBTestHarness;
use Bio::DB::Map::SQL::DBAdaptor;
use Bio::DB::Map::Marker;
use Bio::DB::Map::Map;

my $harness = DBTestHarness->new('markerdb');

ok($harness);

my $db = $harness->get_DBAdaptor();

my $map = new Bio::DB::Map::Map( -name => 'localmap',
				 -units=> 'cM');

ok ($map);
ok ($map->name, 'localmap');
ok ($map->units, 'cM');

my $mapadaptor = $db->get_MapAdaptor();

my $maprc = $mapadaptor->write($map);

ok ( $map->id );
ok ( $maprc->id, $map->id);

my $marker = new Bio::DB::Map::Marker( '-locus' => 'D1S243',
				       '-probe' => 'AFM214yg7',
				       '-length'=> 201,
				       '-pcrfwd'=> 'CACACAGGCTCACATGCC',
				       '-pcrrev'=> 'GCTCCAGCGTCATGGACT',
				       '-type'  => 'ms',
				       '-chrom' => 'chr1' );
				       
ok ($marker);
ok ($marker->locus, 'D1S243');
ok ($marker->probe, 'AFM214yg7');
ok ($marker->length, 201);
ok ($marker->pcrfwd, 'CACACAGGCTCACATGCC');
ok ($marker->pcrrev, 'GCTCCAGCGTCATGGACT');
ok ($marker->type, 'ms' );
ok ($marker->chrom, 1);

$marker->add_position('1.00', 'marshfield');

my ($p) =  ( $marker->each_position );
ok($p->{'map'}, 'marshfield');

my $markeradaptor = $db->get_MarkerAdaptor();

#my $rc = $markeradaptor->write($marker);

#ok ( $marker->id );
#ok ( $rc->id, $marker->id); 

$marker->add_alias('LOCAL0010101', 'localmap' );

$marker->add_alias('RH15245', 'genemap99gb4' );
#$marker->add_alias('stSG729', 'stanford' );
ok($marker->is_alias('LOCAL0010101'));
ok($marker->is_alias('RH15245'));

ok($marker->get_source_for_alias('LOCAL0010101'), 'localmap');
ok($marker->get_source_for_alias('RH15245'), 'genemap99gb4');

#$markeradaptor->write($marker);
#ok($marker->id,1);
#my ($markercopy) = $markeradaptor->get(-name => 'RH15245');
#ok($markercopy);
#ok($markercopy->id, $marker->id);
#ok($markercopy->get_position('marshfield') ==
#   $marker->get_position('marshfield'));
#ok($markercopy->is_alias('RH15245'));
#ok($markercopy->is_alias('LOCAL0010101'));
#ok($markercopy->get_source_for_alias('LOCAL0010101'), 'localmap');
#ok($markercopy->get_source_for_alias('RH15245'), 'genemap99gb4');

#($marker) = $markeradaptor->get('-pcrprimers' => [ qw( CACACAGGCTCACATGCC
#						     GCTCCAGCGTCATGGACT) ] );
#ok ( defined $marker );
#ok ($marker->id);
#ok ($marker->length, 201);

#ok ( $markeradaptor->delete($marker->id) );

#$marker = $markeradaptor->get('-pcrprimers' => [ qw( CACACAGGCTCACATGCC
#						     GCTCCAGCGTCATGGACT) ] );
#ok (! $marker);
