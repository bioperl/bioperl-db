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
    use vars qw($MARKERDATA $WHITEHEADSTS $WHITEHEADALIAS $WHITEHEADRHMAP 
		$WHITEHEADSTSFILE $WHITEHEADALIASFILE $WHITEHEADRHMAPDIR 
		@SOURCES $ONLINE $DEBUG);
    $WHITEHEADSTS = 'http://carbon.wi.mit.edu:8000/ftp/pub/human_STS_releases/may97/5-97.STS.DATA.txt';
    $WHITEHEADALIAS = 'http://carbon.wi.mit.edu:8000/ftp/pub/human_STS_releases/may97/5-97.ALIASES.txt';
    $WHITEHEADRHMAP = 'http://carbon.wi.mit.edu:8000/ftp/pub/human_STS_releases/may97/rhmap';
    $WHITEHEADALIASFILE = "/tmp/markers/whitehead/5-97.ALIASES.txt";
    $WHITEHEADSTSFILE = '/tmp/markers/whitehead/5-97.STS.DATA.txt';
    $WHITEHEADRHMAPDIR = '/tmp/markers/whitehead/rhmap';

    $MARKERDATA = '/tmp/markers/whitehead';    
    $ONLINE = 0;   
    $DEBUG  = 1;
}

# set proxy stuff here where applicable
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

my %sts;
my ($STS) = &get_whitehead_sts_data();

exit if( ! $STS );    
# build STS mapping

my %markers;
my %primers;
while(<$STS>) {
    last if( /^SOURCE/ );
    my ($locus,$assay,$chrom,$source,$genbank,$contig,$fwd,
	$rev,$size) = split("\t", $_);
    next if( ! defined $assay || ! defined $chrom );
    $chrom =~ s/Chr(om)?\s*//i;
    if( ! $fwd || $fwd eq 'NN' || $rev eq 'NN') {
	# we could lookup these since we know genbank id often, but
	# we're only talking 300 out of 67k
	
	next;
    }
    
    $assay =~ s/(AFM\S+)P/$1/;
    $assay =~ s/CHLC\.(\S+)(\.\d+)?/$1/;
    push @{$primers{"$fwd\_$rev"}}, [ uc $assay, $locus, $chrom];
}

my $duplicate;
my %dups;
# read in the maps
foreach my $chrom ( 1..23 ) {
    my %info;
    my $DATA = &get_data_for_chrom($chrom);
    my (@requests,@requests_probes);
    while(<$DATA>) {
	my ($assay,$mappos,$lod) = split;
	my $orig = $assay;
	$assay =~ s/(AFM\S+)P/$1/;
	$assay =~ s/CHLC\.(\S+)(\.\d+)?/$1/;	
	push @{ $markers{uc $assay}}, [ $orig, $mappos, $lod ]; 
    }
   close($DATA);
}

my $duplicates = 0;
my $duplicate_positions = 0;
my $missing_pos = 0; 
while( my($primers,$assayentry) = each %primers ) {    
    if( @$assayentry > 1 ) {
	$duplicates++;
	print "duplicate for $primers :\n";
	foreach my $assayinfo ( @$assayentry ) {
	    my ($assay, $locus, $chrom) = @$assayinfo;
	    if( ! $markers{$assay} ) {
		$missing_pos ++;
		print STDERR "\t-assay $assay had markers but no map position\n";
		next;
	    }
	    
	    foreach my $position ( @{$markers{$assay}} ) {
		print "\t $assay -> ", join(" ". @$position, 
					    $locus, $chrom), "\n";
	    }
	}
	print "---\n";
    } 
}
print "Total duplicates (same primers different positions ) = $duplicates\n";
print "number of missing map positions $missing_pos\n";
sub get_data_for_chrom {
    my ($chrom) = @_;
    $chrom =~ s/23/X/;
    my $fh;
    if( $ONLINE ) {
	my $url = sprintf('%s/Chr%s.rh', $WHITEHEADRHMAP,$chrom);
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
	my $file = sprintf('< %s/Chr%s.rh', $WHITEHEADRHMAPDIR,
			   $chrom);
	$fh = new IO::File($file) or do { 
	    warn("cannot open $file");
	    $fh = undef; };
    }
    return $fh;
}

sub get_whitehead_sts_data {
    my ($STSFH);
    if( $ONLINE ) {

  	my $request = GET $WHITEHEADSTS;
  	my $response = $ua->request($request);
  	if( $response->is_success ) {
  	    $STSFH = new IO::String($response->content);
  	} else { 
  	    warn(sprintf"Error: Request was %s error was %s",
  		 $request->as_string(),
  		 $response->error_as_HTML);
  	    $STSFH = undef;
  	}
    } else {
  	$STSFH = new IO::File("< $WHITEHEADSTSFILE") or do { 
  	    warn("cannot open $WHITEHEADSTSFILE");
  	    $STSFH = undef;
  	};
    }    
    return ($STSFH);
}
