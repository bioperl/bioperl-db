#!/usr/local/bin/perl -w
use strict;

use Bio::DB::Map::SQL::DBAdaptor;
use Bio::DB::Map::Marker;
use Bio::DB::Map::Map;
use Bio::SeqIO;
use IO::File;
use IO::String;
use Carp;

use LWP::UserAgent;
use HTTP::Request::Common;

BEGIN { 
    use vars qw($MARKERDATA $GENETHONURL $GENETHONDATA 
		 $ONLINE $DEBUG);
    $GENETHONURL = 'ftp://ftp.genethon.fr/pub/Gmap/Nature-1995/data';
    $GENETHONDATA = '/tmp/markers/genethon';
    $ONLINE = 0;
    $DEBUG = 1;
}
#set proxy stuff here where applicable
my $ua = new LWP::UserAgent();

use Getopt::Long;

my $host = 'localhost';
my $port   = 3306;
my $dbname = 'markerdb';
my $dbuser = 'root';
my $dbpass = 'undef';
my $module = 'Bio::DB::Map::SQL::DBAdaptor';

&GetOptions( 
	     'online'          => \$ONLINE,
	     'debug'           => \$DEBUG,
	     'host:s'          => \$host,
	     'port:n'          => \$port,
	     'db|dbname:s'     => \$dbname,
	     'user|dbuser:s'   => \$dbuser,
	     'p|dbpass:s'      => \$dbpass,
	     'm|module:s'      => \$module,
	     );

my %props = ( '-host'   => $host,
	      '-dbname' => $dbname,
	      '-user'   => $dbuser);

if( defined $dbpass ) {
    $props{'-dbpass'} = $dbpass;
}

my $db = Bio::DB::Map::SQL::DBAdaptor->new( %props );

my $mapadaptor = $db->get_MapAdaptor();

my $markeradaptor = $db->get_MarkerAdaptor();

# read in the maps
my %markers;
foreach my $chrom ( 1..23 ) {
    my ($DATA) = &get_genethon_data($chrom);
    
    while(<$DATA>) {
	s/\*//g;
	my ($probe,$sexavg,$female,$male,$locus,$genbank,
	    $allelect,$heterozygosity,$fwd,$rev,$genotype,$minmax);
	if( $chrom < 23 ) {
	    ($probe,$sexavg,$female,$male,$locus,$genbank,
	     $allelect,$heterozygosity,$fwd,$rev,$genotype,$minmax) = split;
	} else { 
	    ($probe,$sexavg,$locus,$genbank,
	     $allelect,$heterozygosity,$fwd,$rev,$genotype,$minmax) = split;
	}
	if( $sexavg !~ /^\d+(\.\d+)?$/ ) { next; } # I'm so bad, would rather skip this
	                                   # line that try and figure how to parse
	                                   # it correctly when map info is omitted.

	my ($min,$max) = split('-',$minmax);
	my $len = ($min + $max) / 2;
	
	my $marker = new Bio::DB::Map::Marker( '-locus'   => $locus,
					       '-probe'   => $probe,
					       '-pcrfwd'  => $fwd,
					       '-pcrrev'  => $rev,
					       '-length'  => $len,
					       '-chrom'   => $chrom,
					       '-type'    => 'msat');
	if( $genbank ) {
	    $marker->add_alias($genbank, 'genbank');
	}
	$marker->add_position($sexavg, 'genethon');
	$marker->add_position($male, 'genethon_male') if( $male); 
	$marker->add_position($female, 'genethon_female') if( $female);
	$markers{$probe} = $marker;
    }
}
my ($count,$total,$duplicate) = (0,0,0);
foreach my $marker ( values %markers ) {
    $total++;
    if( ! $marker->pcrfwd ) { 
	if( $DEBUG ) {
	    $markeradaptor->warn("no pcr info, skipping \n". 
				 $marker->to_string);
	}
	$count++;
    }
    if( ! $markeradaptor->write($marker) ) {
	$duplicate++;
	$markeradaptor->add_duplicate_marker($marker);	
    }    
}

print "No primers for $count, $duplicate duplicates, out of $total\n";

sub get_genethon_data {
    my ($chrom) = @_;
    $chrom =~ s/23/X/;
    
    my $fh;
    if( $ONLINE ) {
	my $request = GET $GENETHONURL. "/data_chrom$chrom";
	my $response = $ua->request($request);
	if( $response->is_success ) {
	    $fh = new IO::String($response->content);
	} else { 
	    warn(sprintf"Error: Request was %s error was %s",
		 $request->as_string(),
		 $response->error_as_HTML);
	    $fh = undef;
	}
    } else {
	$fh = new IO::File("< $GENETHONDATA/data_chrom$chrom") or do { 
	    warn("cannot open $GENETHONDATA/data_chrom$chrom");
	    $fh = undef;
	}
    }    
    return $fh;       
}
