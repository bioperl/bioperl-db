# $Id$
# This is a closure that may be used as an argument to the --mergeobjs
# option of load-seqdatabase.pl.
sub {
    my ($old,$new) = @_;

    # merge annotation objects
    my @anns = $old->annotation->get_Annotations();
    foreach my $ann ($new->annotation->get_Annotations()) {
	if(! grep { $_->as_text() eq $ann->as_text(); } @anns) {
	    $old->annotation->add_Annotation($ann);
	}
    }
    # merge features
    if($old->isa("Bio::SeqI")) {
	my @feas = $old->top_SeqFeatures();
	foreach my $fea ($new->top_SeqFeatures()) {
	    if(! grep { 
		$_->location->equals($fea->location) &&
		    ($_->primary_tag eq $fea->primary_tag) &&
		    ($_->source_tag eq $fea->source_tag); } @feas) {
		$old->add_SeqFeature($fea);
	    }
	}
    }
    return $old;
}
