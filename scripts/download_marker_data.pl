#!/usr/local/bin/perl -w

=head1 INFO

This script is intended to help you download the raw files that are
necessary to load publicly available marker maps locally.  The
load_marshfield_map.pl, load_whitehead_markers, load_genethon_data
scripts currently can download all the data from the web/ftp
automatically, but you prefer to store everything locally first this
script should help you.

=head2 REQUIREMENTS

This script assumes you have write permission to /tmp and have
Net::FTP, LWP::USerAgent, File::Path, HTTP::Request::Common modules installed.

=cut

# code begins here
use strict;

BEGIN { 
    # runtime checking for necessary modules
    eval { 
	require LWP::UserAgent;
	require Net::FTP;	
	require File::Path;
	require HTTP::Request::Common;
    };
    if( $@ ) {
	die("Must have LWP::UserAgent, Net::FTP, HTTP::Request::Common, and File::Path installed\n.Warning was:\n$@");
    }
}

use File::Path;
use HTTP::Request::Common;
use Getopt::Long;

use Getopt::Long;
# pls note if you change this, you will also need to change 
# the load_XXX scripts because they look in the 
# /tmp dir by default
use vars qw( $TMPDIR $DEBUG $GENEMAPURL $MARSHFIELDURL $WHITEHEADURL 
	     $GENETHONURL $NCBISTSURL $USAGE);
$GENETHONURL = 'ftp://ftp.genethon.fr/pub/Gmap/Nature-1995/data';
$GENEMAPURL  = 'ftp://ftp.ncbi.nlm.nih.gov/repository/genemap/Mar1999';
$MARSHFIELDURL = 'http://marshfieldclinic.org/research/genetics/Map_Markers/data';
$NCBISTSURL = 'ftp://ftp.ncbi.nlm.nih.gov/repository/dbSTS/human.sts';
$WHITEHEADURL = 'http://carbon.wi.mit.edu:8000/ftp/pub/human_STS_releases/may97';

$TMPDIR = '/tmp';
$DEBUG = 1;
$USAGE = "$0:\n".
    "\t-all\t\t complete downloads for all markers & maps\n".
    "\t-genethon\t get genethon markers and map\n".
    "\t-genemap\t get genemap99 markers and map from NCBI repository\n".
    "\t-marshfield\t get marshfield markers and map\n".
    "\t-whitehead\t get whitehead 1997 STS RH map and markers\n".
    "\t-sts\t\t get NCBI dbSTS e-PCR database\n".
    "\t-help\t\t to show this menu\n";

my ($all, $genethon,$genemap,$marshfield,$whitehead,$sts, $help);

&GetOptions( 
	     'all'          => \$all,
	     'genethon'     => \$genethon,
	     'genemap'      => \$genemap,
	     'marshfield'   => \$marshfield,
	     'whitehead'    => \$whitehead,
	     'sts'          => \$sts,
	     'h|help'         => sub { die($USAGE) },
	     );

my $seen = 0;
foreach ( $all, $genethon,$genemap,$marshfield,$whitehead,$sts ) {
    if( $_ ) { $seen = 1; }
}
if( $help || ! $seen) { die $USAGE }
 
# change the script here to set proxy information
my $ua = new LWP::UserAgent();


die("cannot write in /tmp!") if( ! -w $TMPDIR || ! -d $TMPDIR );

# create genethon dirs
# create marshfield dirs
# create genemap99 dirs
# create whitehead97 dirs

mkpath( ["$TMPDIR/markers"], $DEBUG, 0755);


my ($request,$response,$dir);
if( $all || $genethon ) { 
# let's get genethon data
    $dir = "$TMPDIR/markers/genethon";
    mkpath([$dir], $DEBUG, 0755);

    foreach ( 1..22, 'X' ) {
	my $filename = "data_chrom$_";
	$request = GET "$GENETHONURL/$filename";
	$response = $ua->request($request, "$dir/$filename");
	if( ! $response->is_success ) {
	    print "unable to download $filename from $GENETHONURL/$filename\n";
	}
    }
}

if( $all || $whitehead ) {
    $dir = "$TMPDIR/markers/whitehead";
    mkpath( [$dir],$DEBUG, 0755);
    foreach my $filename (  "5-97.ALIASES.txt", "5-97.STS.DATA.txt" ) {
	$request = GET "$WHITEHEADURL/$filename";
	$response = $ua->request($request, "$dir/$filename");
	if( ! $response->is_success ) {
	    print "unable to download $filename from $WHITEHEADURL/$filename\n";
	}
    }
    $dir = $dir . "/rhmap";
    mkpath([$dir], $DEBUG, 0755);

    foreach ( 1..22, "X") {
	my $filename = sprintf("Chr%s.rh", $_);
	$request = GET "$WHITEHEADURL/rhmap/$filename";
	$response = $ua->request($request, "$dir/$filename");
	if( ! $response->is_success ) {
	    print "unable to download $filename from $WHITEHEADURL/rhmap/$filename\n";
	}	
    }
}

if( $all || $marshfield ) {
    $dir = "$TMPDIR/markers/marshfield";
    mkpath([$dir, "$dir/maps", "$dir/info"],$DEBUG,0755);
    
    foreach ( 1..23 ) {
	# get map
	my $filename = sprintf("maps/map%d.txt", ,$_);
	$request = GET "$MARSHFIELDURL/$filename";
	$response = $ua->request($request,"$dir/$filename");

	if( ! $response->is_success ) {
	    print "unable to download $filename from $MARSHFIELDURL/$filename\n";
	}
	# get info
	$filename = sprintf("info/info%d.txt", $_);	
	$request = GET "$MARSHFIELDURL/$filename";
	$response = $ua->request($request,"$dir/$filename");	
	if( ! $response->is_success ) {
	    print "unable to download $filename from $MARSHFIELDURL/$filename\n";
	}
    }
}

if( $all || $sts ) {
    $dir = "$TMPDIR/markers";
    my $filename = "human.sts";
    $request = GET $NCBISTSURL;
    $response = $ua->request($request,"$dir/$filename");
    if( ! $response->is_success ) {
	print "unable to download $filename from $NCBISTSURL\n";
    }
}

if( $all || $genemap ) {
    $dir = "$TMPDIR/markers/genemap99";
    mkpath([$dir],$DEBUG,0755);    
    my $filename = "genemap99.sts";
    $request = GET "$GENEMAPURL/$filename";
    $response = $ua->request($request,"$dir/$filename");
    if( ! $response->is_success ) {
	print "unable to download $filename from $GENEMAPURL/$filename\n";
    }
    
    foreach my $map ( 'gb4', 'sg3' ) {
	foreach my $chrom ( 1..22, 'X' ) {
	    $filename = sprintf("chr%s.%s", $chrom,$map);
	    $request = GET "$GENEMAPURL/$filename";
	    $response = $ua->request($request, "$dir/$filename");
	    if( ! $response->is_success ) {
		print "unable to download $filename from $GENEMAPURL/$filename\n";
	    }
	}
    }
}

