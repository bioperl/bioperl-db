# -*-Perl-*-
#!/usr/local/bin/perl -w

## Bioperl Test Harness Script for Modules
##


# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.t'

#-----------------------------------------------------------------------
## perl test harness expects the following output syntax only!
## 1..3
## ok 1  [not ok 1 (if test fails)]
## 2..3
## ok 2  [not ok 2 (if test fails)]
## 3..3
## ok 3  [not ok 3 (if test fails)]
##
## etc. etc. etc. (continue on for each tested function in the .t file)
#-----------------------------------------------------------------------


## We start with some black magic to print on failure.
BEGIN { $| = 1; print "1..3\n"; 
	use vars qw($loaded); }

END {print "not ok 1\n" unless $loaded;}

use Bio::DB::BasicUpdateableDB;
use Bio::SeqIO;

$loaded = 1;
print "ok 1\n";    # 1st test passes.
$Bio::EnsemblLite::UpdateableDB::CENTERCODE = 'CHG';

## End of black magic.
##
## Insert additional test code below but remember to change
## the print "1..x\n" in the BEGIN block to reflect the
## total number of tests that will be run. 

open(PWD, "PWD") or die("must have a PWD file");
my ( %hash);

while(<PWD>) {
    chomp;
    my ($key,$val) = split(/:/, $_);
    $hash{uc $key} = $val;
}
close PWD;
my ( $user, $pass,$dbname, $host) = ( $hash{USER}, $hash{PASS},
				      $hash{DB}, $hash{HOST});

$dbname = 'seqdb';
print "ok 2\n";
eval {
    my $seqio = new Bio::SeqIO(-format=>'GenBank', -file=>"t/AP000868.gb");
    my $out = Bio::SeqIO->new(-format=>'GenBank', -fh=>\*STDERR);

    my @seqs;

    my $seqdb = new Bio::DB::BasicUpdateableDB(-dbname=>$dbname, 
						   -host=>$host, 
						   -user=>$user,
						   -pass=>$pass);

    while( my $seq = $seqio->next_seq() ) {
#	$out->write_seq($seq);
	my $dbseq = $seqdb->get_Seq_by_id($seq->display_id);
	if( defined $dbseq && ref($dbseq) ) {
#	    $out->write_seq($dbseq);
	    $seqdb->write_seqs(undef, undef, [ $dbseq ] );	    
	} else {
	    print STDERR " -- Did not get a seq back\n";
	}
    }
    $seqdb->DESTROY;
						   
};

if ($@) {
	warn "$@";	
}
print "ok 3\n";



