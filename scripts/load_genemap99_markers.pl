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
    use vars qw($GENEMAPDATA $GENEMAPURL $ONLINE $DEBUG);
    $GENEMAPURL = 'ftp://ftp.ncbi.nlm.nih.gov/repository/genemap/Mar1999';
    $GENEMAPDATA = '/tmp/markers/genemap99';
    $ONLINE = 0;
    $DEBUG = 0;
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

my %markers;
my ($EPCR) = &get_genemap_data();

while(<$EPCR>) {
    my ($rhdb,$fwd,$rev,$len,$map,$chrom,$start, $score) = split;
    next if ( !$rhdb || $rhdb =~ /[\+\?\-]/ || $fwd =~ /^[\+\?\-]/ );
    $chrom =~ s/Chr([\dX]+).+/$1/;
    if( $len !~ /\d+/ ) { 
	print "len is $len for line $_\n";
	$len = 200;
    }
    my $marker = new Bio::DB::Map::Marker('-locus'  => $rhdb,
					  '-chrom'  => $chrom,
					  '-pcrfwd' => $fwd,
					  '-pcrrev' => $rev,
					  '-length' => $len );
					   
    $marker->add_alias($rhdb, 'RHdb');
    $markers{$rhdb} = $marker;
}

close($EPCR);
# read in the map data even though it is stored in the ePCR file
my %finalmarkers;
foreach my $map ( qw(gb4 sg3) ) {
    foreach my $chrom ( 1..23 ) {    
	my ($DATA) = &get_genemap_map_data($chrom,$map);
	while(<$DATA>) {
	    next if( /^\#/ || /^\s+$/ ); # skip header line
	    my ($chrom,$pos,$odds, $type,$rhdb,$probe, $lab) = split;
	    my $marker = $finalmarkers{$probe} || $markers{$rhdb};
	    if( ! defined $marker ) {
		print STDERR "no marker found for probe $probe\n" if( $DEBUG);
		next;
	    }
	    $type =~ s/\*//;
	    print "probe is null for $_" if( ! $probe);
	    $marker->probe($probe);
	    $marker->type($type);
	    $marker->add_position($pos, 'genemap99'. $map);
	    $finalmarkers{$probe} = $marker;
	}
    }
}

my ($count,$total,$duplicate) = (0,0,0);
foreach my $marker ( values %finalmarkers ) {
    $total++;
    if( ! $marker->pcrfwd ) { 
	if( $DEBUG ) {
	    $markeradaptor->warn("no pcr info, skipping \n". 
				 $marker->to_string);
	}
	$count++;
	next;
    }
    if( ! $markeradaptor->write($marker) ) {
	$duplicate++;
	$markeradaptor->add_duplicate_marker($marker);	
    }    
}
print "No primers for $count, $duplicate duplicates, out of $total\n";

sub get_genemap_data {
    my $fh;
    if( $ONLINE ) {
	my $request = GET $GENEMAPURL. "/genemap99.sts";
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
	$fh = new IO::File("< $GENEMAPDATA/genemap99.sts") or do { 
	    warn("cannot open $GENEMAPDATA/genemap99.sts");
	    $fh = undef;
	}
    }    
    return $fh;       
}

sub get_genemap_map_data {
    my ($chrom,$map) = @_;
    if( $map ne 'gb4' && $map ne 'sg3' ) {
	warn("must specify either 'gb4' or 'sg3' maps");  
    }

    $chrom =~ s/23/X/;
    my $filename = sprintf("chr%s.%s", $chrom,$map);
    my $fh;
    if( $ONLINE ) {
	my $request = GET sprintf("%s/%s",$GENEMAPURL,$filename);
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
	$fh = new IO::File("< $GENEMAPDATA/$filename") or do { 
	    warn("cannot open $GENEMAPDATA/$filename");
	    $fh = undef;
	}
    }    
    return $fh;    
}
