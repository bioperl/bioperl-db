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
    use vars qw($MARKERDATA $MARSHFIELDURL $NCBIDATAURL $STSDATA 
		$NCBI_STSURL $ONLINE);
    $MARSHFIELDURL = 'http://marshfieldclinic.org/research/genetics/Map_Markers/data';
    $MARKERDATA = '/home/markers';
    $STSDATA = '/home/data/sts/human.sts';
    
    $NCBI_STSURL = 'ftp://ftp.ncbi.nlm.nih.gov/repository/dbSTS/human.sts';
    $ONLINE = 1;
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

my @mapnames = qw(marshfield marshfield_female marshfield_male);
my %maps;

foreach my $name ( @mapnames ) {
    $maps{$name} = $mapadaptor->get('-name' => $name);
}

# read in the maps
my %markers;
foreach my $chrom ( 1..23 ) {
    my $MAP = &get_map_data_for_chrom($chrom);
    # skip the 1st 2 header lines
    <$MAP>; <$MAP>;
    while(<$MAP>) {
	s/^\*//;
	s/^x//;
	my ($id,$probe,$locus,@mapvals) = split;

	if( $id !~ /^\d+$/ ) { 
	    # something is wrong with the format
	    die("got an unexpected line: $_");
	} 
	$locus = '' unless ( $locus !~ /Unknown/i );
	$markers{$probe} = new Bio::DB::Map::Marker ( -probe => $probe,
						      -locus => $locus,
						      -chrom => $chrom,
						      -type  => 'msat');

	foreach my $name ( @mapnames ) {
	    $markers{$probe}->add_position(shift @mapvals, $name);
	}

	<$MAP>;			# skip the next line because it is just
	# the distance between markers	
    }
    close($MAP);
    
    my %info;
    my $INFO = &get_info_data_for_chrom($chrom);
    <$INFO>; <$INFO>;
    my (@requests,@requests_probes);
    while(<$INFO>) {
	s/^\*//;
	s/^x//;

	my ($probe,$locus,$genbank) = split;
	my $struct = { 'probe' => $probe,
		       'locus' => $locus,
		       'genbank' => $genbank };

	if( $genbank !~ /Unknown/i  ) {
	    $info{$genbank} =  $struct; 
	}
	# I checked an one locus appears twice
	# and these are actually the same marker
	# M758B6-1/M758B621

	$info{$locus} = $struct;
    }
    close($INFO);

    my $STS = &get_sts_data();
    
    while(<$STS>) {
	my ($id,$fwd,$rev,$len,$locus,$chrom,$genbank) = split;
	my $probe = '';

	if( $genbank =~ /-/i ) { $genbank = $locus; } 
	else { 
	    foreach my $g ( split(/;/,$genbank) ) {
		if( $info{$g} ) { 
		    $probe = $info{$g}->{'probe'};
		    last;
		}
	    }
	}
	if( ! $probe ) {
	    $probe = $info{$locus}->{'probe'};
	} 
	if( ! $probe) {
#	    print "skipping $locus $genbank\n";
	    next;
	}

	if( $markers{$probe} ) { 
	    if( ! $markers{$probe}->locus) {$markers{$probe}->locus($locus) ;}
	    elsif( $markers{$probe}->locus ne $locus  ) {
		print "marker $probe, locus $locus, did not match ", 
		$markers{$probe}->locus, "\n";		
	    }
	    $markers{$probe}->pcrfwd($fwd);
	    $markers{$probe}->pcrrev($rev);
	    $markers{$probe}->length($len);

	} else {
 	    # won't have a map position
	    # but we can still load it for
	    # future markers

# skip doing this for now since we are really just loading marshfield markers
#	    $markers{$probe} = new Bio::DB::Map::Marker
#		( '-probe' => $probe,
#		  '-locus' => $locus,
#		  '-pcrfwd'=> $fwd,
#		  '-pcrrev'=> $rev,
#		  '-length'=> $length);	    
	}	
    }
    close($STS);
}

my ($count,$total) = (0,0);
foreach my $marker ( values %markers ) {
    $total++;
    if( ! $marker->pcrfwd ) { 
	    $markeradaptor->warn("no pcr info, skipping \n". 
				 $marker->to_string);
	    $count++;
	    next;	    
	} 
    $markeradaptor->write($marker);
    $total++;
}
print "skipped $count out of $total\n";

sub get_map_data_for_chrom {
    my ($chrom) = @_;
    my $fh;
    if( $ONLINE ) {
	my $url = sprintf('%s/maps/map%d.txt', $MARSHFIELDURL,$chrom);
	my $request = GET $url;
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
	my $file = sprintf('< %s/maps/map%d.txt', $MARKERDATA,
			   $chrom);
	$fh = new IO::File($file) or do { 
	    warn("cannot open $file");
	    $fh = undef; };
    }
    return $fh;
}

sub get_info_data_for_chrom {
    my ($chrom) = @_;
    my $fh;
    if( $ONLINE ) {
	my $url = sprintf('%s/info/info%d.txt', $MARSHFIELDURL,$chrom);
	my $request = GET $url;
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
	my $file = sprintf('< %s/info/info%d.txt', $MARKERDATA,
			   $chrom);
	$fh = new IO::File($file) or do { 
	    warn("cannot open $file");
	    $fh = undef; };
    }
}

sub get_sts_data {
    my $fh;
    if( $ONLINE ) {
	my $request = GET $NCBI_STSURL;
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
	$fh = IO::File("< $STSDATA") or do { 
	    warn("cannot open $STSDATA");
	    $fh = undef;
	}
    }    
    return $fh;       
}
