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
		$NCBI_STSURL $ONLINE $DEBUG);
    $MARSHFIELDURL = 'http://marshfieldclinic.org/research/genetics/Map_Markers/data';
    $MARKERDATA = '/tmp/markers/marshfield';
    $STSDATA = '/tmp/markers/human.sts';
    
    $NCBI_STSURL = 'ftp://ftp.ncbi.nlm.nih.gov/repository/dbSTS/human.sts';
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

my @mapnames = qw(marshfield marshfield_female marshfield_male);
my %maps;

foreach my $name ( @mapnames ) {
    $maps{$name} = $mapadaptor->get('-name' => $name);
}

my %sts;
my $STS = &get_sts_data();
exit if( ! $STS );    
# build STS
while(<$STS>) {
    my ($id,$fwd,$rev,$len,$locus,$chrom,$genbank) = split;

    my $probe = '';
    $locus =~ s/CHLC\.//;
    
    $sts{$locus} = [ $fwd,$rev,$len ];
    if( $genbank eq '-' ) {
	# do nothing
    } elsif( $genbank =~ /;/ ) {
	foreach my $g ( split(/;/,$genbank) ) {	    
	    $sts{$g} = [ $fwd,$rev,$len ];
	}
    } else {
	$sts{$genbank} = [ $fwd,$rev,$len ];
    }
}
close($STS);

# read in the maps
my %markers;
foreach my $chrom ( 1..23 ) {
    my $MAP = &get_map_data_for_chrom($chrom);
    last if ( ! $MAP);
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
    last if ( ! $INFO);
    <$INFO>; <$INFO>;
    my (@requests,@requests_probes);
    while(<$INFO>) {
	s/^\*//;
	s/^x//;
	
	my ($probe,$locus,$genbank) = split;

	if( $locus =~ /Unknown/i  ) {
	    $locus = $probe;
	}
	
	if( $genbank =~ /Unknown/i  ) {
	    $genbank = $locus;
	}
	
        # I checked an one locus appears twice
	# and these are actually the same marker
	# M758B6-1/M758B621
	my $stsval = undef;
	my $marker = undef;
	if( $sts{$genbank} ) {	    
	    $stsval = $sts{$genbank};	    
	} elsif( $sts{$locus} ) {
	    $stsval = $sts{$locus};
	} elsif( $sts{$probe} ) {
	    $stsval = $sts{$probe};
	}

	if( ! $stsval ) { 
	    print "could not find stsval for $probe $locus $genbank\n" if($DEBUG);
	    next; }
	
	if( $markers{$probe} ) {
	    $marker = $markers{$probe};	    
	} elsif( $markers{$locus} ) {
	    $marker = $markers{$locus};
	} elsif( $markers{$genbank} ) {
	    $marker = $markers{$genbank};
	}
	if( ! $marker ) {
	    print "unable to find marker for $probe $locus $genbank\n" if($DEBUG);
	    next;
	}
	
	$marker->pcrfwd($stsval->[0]);
	$marker->pcrrev($stsval->[1]);
	$marker->length($stsval->[2]);	    
	$markers{$marker->probe} = $marker;
    }
    close($INFO);
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
	next;
    }    
    if( ! $markeradaptor->write($marker) ) {
	$duplicate++;
	if( ! $markeradaptor->add_duplicate_marker($marker) ) {
	    print STDERR "no duplicate marker found for ", $marker->to_string(), "\n";
	}
    }
}
print "No primers for $count, $duplicate duplicates, out of $total\n";

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
    return $fh;
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
	$fh = new IO::File("< $STSDATA") or do { 
	    warn("cannot open $STSDATA");
	    $fh = undef;
	}
    }    
    return $fh;       
}
