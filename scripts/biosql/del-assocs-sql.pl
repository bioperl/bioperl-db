# $Id$
#
# This is a closure that may be used as an argument to the --mergeobjs
# option of load-seqdatabase.pl.
#
# This scriptlet will remove all annotation and features associated
# with the old entry using direct SQL queries. It is therefore specific
# to the schema; in fact it is presently specific to the Oracl version
# of the biosql schema. However, it is easily adapted to the mysql/Pg
# versions by adapting the primary key/foreign key names.
#
# The reason to issue direct SQL queries is purely efficiency when
# updating the data content.
#
# Other than that, the way of removing annotation association for a
# found entry is identical to the idea behind freshen-annot.pl.
#
sub {
    my ($old,$new,$db) = @_;

    # the found object is a persistent object, so we have access to
    # its adaptor for caching statements and getting the database handle
    my $adp = $old->adaptor();

    # the tables where we delete by simple foreign key matching
    my @del_by_fk_tables = ("bioentry_qualifier_value",
                            "anncomment",
                            "bioentry_reference",
                            "bioentry_dbxref",
                            "seqfeature",
                            "bioentry_relationship");

    # delete for each table by foreign key
    foreach my $tbl (@del_by_fk_tables) {
        # build the sql statement
        my $sql = "DELETE FROM $tbl WHERE ent_oid = ?";
        # if it's the relationship table we need to add a term constraint
        if ($tbl eq "bioentry_relationship") {
            $sql .= " AND trm_oid = "
                . "(SELECT t.Oid FROM Term t, Ontology o "
                . "WHERE t.Ont_Oid = o.Oid "
                . "AND t.name = 'cluster member' "
                . "AND o.name = 'Relationship Type Ontology')";
        }
        # we use DBI's facility for statement caching here
        my $sth = $adp->dbh->prepare_cached($sql);
        # and execute with the primary key
        if (! $sth->execute($old->primary_key())) {
            $old->warn("failed to execute sql statement ($sql): "
                       . $sth->errstr);
            $sth->finish();
        }
    }
    # done
    return $new;
}
