#!/usr/local/bin/perl -w

$ior_file = shift;

use CORBA::ORBit idl => [ 'biocorba.idl' ];

$ior_file ||= "bioenv.ior";
$orb = CORBA::ORB_init("orbit-local-orb");

open(F,"$ior_file") || die "Could not open $ior_file";
$ior = <F>;
chomp $ior;
close(F);

$bioenv = $orb->string_to_object($ior);


$names = $bioenv->get_SeqDB_names();

foreach $name ( @$names ) {
    print "Got sequence db $name\n";
}

$name = shift @$names;

$db = $bioenv->get_SeqDB_by_name($name,0);

$names = $db->accession_numbers();

foreach my $n ( @$names ) {
    print STDERR "Got $n\n";
    $seq = $db->get_Seq($n,0);
    print STDERR "Got $seq ",$seq->display_id," and ",$seq->subseq(1,10),"\n";
    $vec = $seq->all_SeqFeatures(0);
    $it  = $vec->iterator();

    while( $it->has_more ) {
	$f = $it->next();
	print STDERR "Has feature ",$f->start," ",$f->end," ",$f->type," ",$f->source,"\n";
	$f->unref();
    }

    $seq->unref();
}










