# $Id$
#
# This is a closure that may be used as an argument to the --mergeobjs
# option of load-seqdatabase.pl.
#
# The goal is to retain existing features and annotation, avoid updates of
# those, but add from the new object all features and annotation that wasn't
# yet on the database object.
#
sub {
    my ($old,$new,$db) = @_;

    # merge annotation objects
    if($old->isa("Bio::AnnotatableI")) {
	# remove the old ones from the object (this doesn't remove them
	# from the database, nor does it remove the associations)
	my @anns = $old->annotation->remove_Annotations();
	my $r = 1;
	foreach (@anns) { $r = $_->rank if $_->rank > $r; }
	foreach my $ann ($new->annotation->get_Annotations()) {
	    # only add on those that weren't there yet (i.e., don't
	    # update annotations, just add new ones)
	    if(! grep { $_->as_text() eq $ann->as_text(); } @anns) {
		$ann = $db->create_persistent($ann);
		$ann->rank(++$r);
		$old->annotation->add_Annotation($ann);
	    }
	}
    }
    # merge features
    if($old->isa("Bio::SeqI")) {
	# same story here: remove existing ones from the object as we
	# don't want them updated (removing from the object does not
	# delete from the database)
	my @feas = $old->flush_SeqFeatures();
	my $r = 1;
	foreach (@feas) { $r = $_->rank if $_->rank > $r; }
	foreach my $fea ($new->top_SeqFeatures()) {
	    # add on those with not yet seen location, primary_tag or
	    # source_tag
	    if(! grep { 
		$_->location->equals($fea->location) &&
		    ($_->primary_tag eq $fea->primary_tag) &&
		    ($_->source_tag eq $fea->source_tag); } @feas) {
		$fea = $db->create_persistent($fea);
		$fea->rank(++$r);
		$old->add_SeqFeature($fea);
	    }
	}
    }
    return $old;
}
