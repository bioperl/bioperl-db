
use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;    
    plan tests => 14;
}
#END { unlink( 't/cjm_test.gb') }
use DBTestHarness;
use Bio::DB::SQL::DBAdaptor;
use Bio::SeqIO;
use Bio::Root::IO;

$harness = DBTestHarness->new();

ok $harness;

$db = $harness->get_DBAdaptor();

ok $db;

$seqio = Bio::SeqIO->new('-format' => 'GenBank',-file => Bio::Root::IO->catfile('t','data','revcomp_mrna.gb'));

$seq = $seqio->next_seq();

$out = Bio::SeqIO->new( -file => '>t/revcomp_mrna_test.gb' , -"format" => 'GenBank');


$out->write_seq($seq);

foreach my $sf ( $seq->top_SeqFeatures ) {
    use Data::Dumper;
    print Dumper $sf;
    die;
}

ok $out;
