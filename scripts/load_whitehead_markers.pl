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
    $DEBUG  = 0;
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

my $db = Bio::DB::Map::SQL::DBAdaptor->new( %props );

my $markeradaptor = $db->get_MarkerAdaptor();

my %sts;
my ($STS,$ALIAS) = &get_whitehead_sts_data();

exit if( ! $STS || ! $ALIAS );    
# build STS mapping

my %markers;

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
    my $marker = new Bio::DB::Map::Marker ( -probe => $assay,
					    -locus => $locus,
					    -chrom => $chrom,
					    -type  => 'rh',
					    -pcrfwd=> $fwd,
					    -pcrrev=> $rev, 
					    -length=> $size || 0);    
    $marker->add_alias($genbank, 'genbank');
    
    $markers{uc $assay} = \$marker;

    if( $locus ) {
	$markers{uc $locus} = \$marker;
    }
    if( $genbank ) {
	$markers{uc $genbank} = \$marker;
    }
}

while(<$STS> ){
    last if( /^\s+$/);
    my ($sourceid,$desc) = split(/\s+/,$_,2);
    $SOURCES[$sourceid] = $desc;
}
close($STS);

# now process alias file
<$ALIAS>; <$ALIAS>; # skip the 1st 2 line

while(<$ALIAS>) {
    chomp;
    my @line = split("\t",$_);
    my ($name,$genbank,$dbsts, @aliases) = @line;
    my $marker;
    $name = uc $name;
    $genbank = uc $genbank;
    
    if( defined $markers{$name} ) {
	$marker = $markers{$name};
    } elsif( $genbank && defined $markers{$genbank} ) {
	$marker = $markers{$genbank};
    } else { 
	my @a;
	foreach my $alias ( @aliases ) {
	    if( !defined $marker && 
		defined ( $marker = $markers{uc $alias}) ) { 		
		print "found one ($alias) based on alias\n" if( $DEBUG);
	    } else { 
		push @a, $alias;
	    }
	}
	@aliases = @a;
	if( ! defined $marker ) {
	    print "could not find marker for line ", join(",", @line), "\n" if( $DEBUG);
	    next;
	}
    }    
    
    if( $dbsts ) {
	$$marker->add_alias($dbsts, 'dbsts');
	$markers{$dbsts} = $marker;
    }
    if( $genbank && ! $$marker->is_alias($genbank) ) {
	$$marker->add_alias($genbank, 'genbank');
	$markers{$genbank} = $marker;
    }
    
    # get a unique list
    my %seen;
    map { $_ && $seen{$_}++ } ( $name, $genbank, @aliases);
    @aliases = keys %seen;
    foreach my $alias ( @aliases ) {	    
	$$marker->add_alias($alias);	
	$markers{uc $alias} = $marker;
    }
}

# read in the maps
foreach my $chrom ( 1..23 ) {
    my %info;
    my $DATA = &get_data_for_chrom($chrom);
    my (@requests,@requests_probes);
    while(<$DATA>) {
	my ($assay,$mappos,$lod) = split;
	$assay =~ s/(AFM\S+)P/$1/;
	my $marker = $markers{uc $assay};
	if( ! defined $marker ) {
	    print "marker $assay is not found in loaded markers\n" if( $DEBUG);
	    next;
	}
	$$marker->add_position($mappos,'whitehead');
    }
   close($DATA);
}

my ($count,$total,$duplicate) = (0,0,0);
my %seen;
foreach my $marker ( values %markers ) {
    next if( $seen{$$marker->probe}++ || $$marker->id ); # already loaded;
    
    $total++;
    if( ! $$marker->pcrfwd ) {
	$markeradaptor->warn("no pcr info, skipping \n". 
				 $$marker->to_string);
	$count++;
	next;	    
    } 

    if( ! $markeradaptor->write($$marker) ) {
	$duplicate++;
	$markeradaptor->add_duplicate_marker($$marker);	
    }    
}
print "skipped $count, $duplicate duplicates out of $total\n";

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
    my ($STSFH, $ALIASFH);
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

  	$request = GET $WHITEHEADALIAS;
  	$response = $ua->request($request);
  	if( $response->is_success ) {
  	    $ALIASFH = new IO::String($response->content);
  	} else { 
  	    warn(sprintf"Error: Request was %s error was %s",
  		 $request->as_string(),
  		 $response->error_as_HTML);
  	    $ALIASFH = undef;
  	}	
    } else {
  	$STSFH = new IO::File("< $WHITEHEADSTSFILE") or do { 
  	    warn("cannot open $WHITEHEADSTSFILE");
  	    $STSFH = undef;
  	};
  	$ALIASFH = new IO::File("< $WHITEHEADALIASFILE") or do { 
  	    warn("cannot open $WHITEHEADALIASFILE");
  	    $ALIASFH = undef;
  	};
    }    
    return ($STSFH, $ALIASFH);
}
