# $Id$
#
# This is a closure that may be used as an argument to the --mergeobjs
# option of load-seqdatabase.pl.
#
# The goal is to trigger an update only if the version has changed from
# the old entry to the new one. In that case we remove all annotation and
# features for that entry from the database, as updating them is difficult 
# due to poor unique key definitions. If the version is unchanged, we'll
# assume the database entry is up-to-date already and skip the new entry.
#
sub {
    my ($old,$new,$db) = @_;

    if($old->isa("Bio::IdentifiableI") && $new->isa("Bio::IdentifiableI")) {
	if((defined($old->version) xor defined($new-version)) ||
	   ($old->version < $new->version)) {
	    # remove existing features
	    if($old->can('all_SeqFeatures')) {
		foreach my $fea ($old->all_SeqFeatures()) {
		    $fea->remove();
		}
	    }
	    # remove existing annotation
	    if($old->isa("Bio::AnnotatableI")) {
		my $anncoll = $old->annotation();
		$anncoll->remove();
	    }
	    print STDERR "about to update ",$new->object_id()," (version ",
	                 ($old->version() || "<undef>")," -> ",
	                 ($new->version() || "<undef>"),"\n";
	} else {
	    # skip the update
	    $new = undef;
	}
    } else {
	warn "Either ".ref($old->obj)." or ".ref($new->obj).
	    " is not IdentifiableI - cannot compare by version";
    }
    return $new;
}
