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

use Bio::EnsemblLite::UpdateableDB;
use Bio::SeqIO;

$loaded = 1;
print "ok 1\n";    # 1st test passes.
$Bio::EnsemblLite::UpdateableDB::CENTERCODE = 'CHG';

## End of black magic.
##
## Insert additional test code below but remember to change
## the print "1..x\n" in the BEGIN block to reflect the
## total number of tests that will be run. 

eval {
    my $seqio = new Bio::SeqIO(-format=>'GenBank', -file=>"t/parkin.gb");
    my @seqs;
    while( my $seq = $seqio->next_seq() ) {
	push @seqs,$seq;
    }
    my $seqdb = new Bio::EnsemblLite::UpdateableDB(-dbname=>'seqdb', -user=>'jason',
						   -host=>'genemap', -pass=>'superman');
    $seqdb->write_seqs( undef, \@seqs);
    foreach my $seq ( @seqs ) {
	print "id is ", $seq->primary_id, ", display is ", $seq->display_id, 
	", accession is ", $seq->accession_number, "\n";
    }
    $seqdb->DESTROY;
						   
};

if ($@) {
	warn "$@";
} else {
	print "ok 2\n";
}

