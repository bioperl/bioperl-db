# $Id$
#
# BioPerl module for Bio::DB::BioSQL::SpeciesAdaptorDriver
#
# Cared for by Hilmar Lapp <hlapp at gmx.net>
#
# Copyright Hilmar Lapp
#
# You may distribute this module under the same terms as perl itself

#
# (c) Hilmar Lapp, hlapp at gmx.net, 2002.
# (c) GNF, Genomics Institute of the Novartis Research Foundation, 2002.
#
# You may distribute this module under the same terms as perl itself.
# Refer to the Perl Artistic License (see the license accompanying this
# software package, or see http://www.perl.com/language/misc/Artistic.html)
# for the terms under which you may use, modify, and redistribute this module.
# 
# THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
# MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#

# POD documentation - main docs before the code

=head1 NAME

Bio::DB::BioSQL::SpeciesAdaptorDriver - DESCRIPTION of Object

=head1 SYNOPSIS

Give standard usage here

=head1 DESCRIPTION

Describe the object here

=head1 FEEDBACK

=head2 Mailing Lists

User feedback is an integral part of the evolution of this and other
Bioperl modules. Send your comments and suggestions preferably to
the Bioperl mailing list.  Your participation is much appreciated.

  bioperl-l@bioperl.org              - General discussion
  http://bioperl.org/MailList.shtml  - About the mailing lists

=head2 Reporting Bugs

Report bugs to the Bioperl bug tracking system to help us keep track
of the bugs and their resolution. Bug reports can be submitted via
email or the web:

  bioperl-bugs@bioperl.org
  http://bugzilla.bioperl.org/

=head1 AUTHOR - Hilmar Lapp

Email hlapp at gmx.net

=head1 CONTRIBUTORS

Additional contributors names and emails here

=head1 APPENDIX

The rest of the documentation details each of the object methods.
Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::DB::BioSQL::mysql::SpeciesAdaptorDriver;
use vars qw(@ISA);
use strict;

# Object preamble - inherits from BasePersistenceAdaptorDriver

use Bio::DB::BioSQL::mysql::BasePersistenceAdaptorDriver;

@ISA = qw(Bio::DB::BioSQL::mysql::BasePersistenceAdaptorDriver);


=head2 new

 Title   : new
 Usage   : my $obj = new Bio::DB::BioSQL::SpeciesAdaptorDriver();
 Function: Builds a new Bio::DB::BioSQL::SpeciesAdaptorDriver object 
 Returns : an instance of Bio::DB::BioSQL::SpeciesAdaptorDriver
 Args    :


=cut

sub new {
    my($class,@args) = @_;

    my $self = $class->SUPER::new(@args);

    return $self;
}

=head2 prepare_findbypk_sth

 Title   : prepare_findbypk_sth
 Usage   :
 Function: Prepares and returns a DBI statement handle with one placeholder for
           the primary key. The statement is expected to return the primary key
           as the first and then as many columns as 
           $adp->get_persistent_slots() returns, and in that order.

 Example :
 Returns : A DBI prepared statement handle with one placeholder
 Args    : The Bio::DB::BioSQL::BasePersistenceAdaptor derived object 
           (basically, it needs to implement dbh() and get_persistent_slots()).
           A reference to an array of foreign key slots (class names).


=cut

sub prepare_findbypk_sth{
    my ($self,$adp,$fkslots) = @_;

    # get table name and the primary key name
    my $table = $self->table_name($adp);
    my $node_table = $self->table_name("TaxonNode");
    my $pkname = $self->primary_key_name($table);
    my $fkname = $self->foreign_key_name("TaxonNode");
    # gather attributes
    my @attrs = $self->_build_select_list($adp,$fkslots);
    # create the sql statement
    my $sql = "SELECT " .
	join(", ", @attrs) .
	" FROM $node_table, $table".
	" WHERE $node_table.$pkname = $table.$fkname".
	" AND $node_table.$pkname = ?";
    $adp->debug("preparing PK select statement: $sql\n");
    # prepare statement and return
    return $adp->dbh()->prepare($sql);
}

=head2 prepare_findbyuk_sth

 Title   : prepare_findbyuk_sth
 Usage   :
 Function: Prepares and returns a DBI SELECT statement handle with as many
           placeholders as necessary for the given unique key.

           The statement is expected to return the primary key as the first and
           then as many columns as $adp->get_persistent_slots() returns, and in
           that order.
 Example :
 Returns : A DBI prepared statement handle with as many placeholders as 
           necessary for the given unique key
 Args    : The calling Bio::DB::BioSQL::BasePersistenceAdaptor derived object 
           (basically, it needs to implement dbh() and get_persistent_slots()).
           A reference to a hash with the names of the object''s slots in the
           unique key as keys and their values as values.
           A reference to an array of foreign key objects or slots 
           (class names if slot).


=cut

sub prepare_findbyuk_sth{
    my ($self,$adp,$ukval_h,$fkslots) = @_;

    # get the slots for which we need columns
    my @slots = $adp->get_persistent_slots();
    # get the slot/attribute map
    my $table = $self->table_name($adp);
    my $node_table = $self->table_name("TaxonNode");
    my $pkname = $self->primary_key_name($node_table);
    my $fkname = $self->foreign_key_name("TaxonNode");
    my $slotmap = $self->slot_attribute_map($table);
    # SELECT columns
    my @attrs = $self->_build_select_list($adp,$fkslots);
    # WHERE clause constraints
    my @cattrs = ();
    foreach (keys %$ukval_h) {
	my $col;
	if(exists($slotmap->{$_})) {
	    $col = $slotmap->{$_};
	}
	push(@cattrs, $col || "NULL");
	$self->warn("slot $_ is in unique key, but can't be mapped to ".
		    "an entity column: you won't find anything")
	    unless $col;
    }
    # create the sql statement
    my $sql = "SELECT " . join(", ", @attrs) .
	" FROM $node_table, $table".
	" WHERE $node_table.$pkname = $table.$fkname AND ".
	join(" AND ", map { "$_ = ?"; } @cattrs);
    $adp->debug("preparing UK select statement: $sql\n");
    # prepare statement and return
    return $adp->dbh()->prepare($sql);
}

=head2 prepare_delete_sth

 Title   : prepare_delete_sth
 Usage   :
 Function: Creates a prepared statement with one placeholder variable suitable
           to delete one row from the respective table the given class maps to.

           We override this here in order to delete from the taxon
           node table, not the taxon name table. The node table will
           cascade to the name table.

 Example :
 Returns : A DBI statement handle for a prepared statement with one placeholder
 Args    : The calling adaptor (basically, it needs to implement dbh()).
           Optionally, additional arguments.


=cut

sub prepare_delete_sth{
    my ($self, $adp) = @_;

    # default is a simple DELETE statement
    #
    # we need the table name and the name of the primary key
    my $tbl = $self->table_name("TaxonNode");
    my $pkname = $self->primary_key_name($tbl);
    # straightforward SQL:
    my $sql = "DELETE FROM $tbl WHERE $pkname = ?";
    $adp->debug("preparing DELETE statement: $sql\n");
    my $sth = $adp->dbh()->prepare($sql);
    # done
    return $sth;
}

=head2 insert_object

 Title   : insert_object
 Usage   :
 Function:
 Example :
 Returns : The primary key of the newly inserted record.
 Args    : A Bio::DB::BioSQL::BasePersistenceAdaptor derived object
           (basically, it needs to implement dbh(), sth($key, $sth),
	    dbcontext(), and get_persistent_slots()).
	   The object to be inserted.
           A reference to an array of foreign key objects; if any of those
           foreign key values is NULL (some foreign keys may be nullable),
           then give the class name.


=cut

sub insert_object{
    my ($self,$adp,$obj,$fkobjs) = @_;
    
    # get the INSERT statements: we need one for the taxon node and one for
    # the taxon name table
    my $cache_key_t = 'INSERT taxon '.ref($obj);
    my $cache_key_tn = 'INSERT taxname '.ref($obj);
    my $sth_t = $adp->sth($cache_key_t);
    my $sth_tn = $adp->sth($cache_key_tn);
    # we need the slot map regardless of whether we need to construct the
    # SQL or not, because we need to know which slots do not map to a column
    # (indicated by them being mapped to undef)
    my $table = $self->table_name($adp);
    my $node_table = $self->table_name("TaxonNode");
    my $fkname = $self->foreign_key_name("TaxonNode");
    my $slotmap = $self->slot_attribute_map($table);
    $self->throw("no slot/attribute map for table $table") unless $slotmap;
    # we'll need the db handle in any case
    my $dbh = $adp->dbh();
    # if not cached, create SQL and prepare statement
    if(! $sth_tn) {
	# Prepare the taxon insert statement first. There is really not a
	# lot for being generic here. Also, I'm afraid we need to mandate
	# that there is a column mapping to ncbi_taxid.
	my $sql = "INSERT INTO $node_table (".$slotmap->{"ncbi_taxid"}.
	    ") VALUES (?)";
	$adp->debug("preparing INSERT taxon: $sql\n");
	$sth_t = $dbh->prepare($sql);
	$adp->sth($cache_key_t, $sth_t);
	# now prepare the taxon_name insert statement
	my @attrs = ($fkname,
		     $slotmap->{"binomial"},
		     $slotmap->{"name_class"});
	$sql = "INSERT INTO " . $table . " (" . join(", ", @attrs) .
	    ") VALUES (?, ?, ?)";
	$adp->debug("preparing INSERT taxon_name statement: $sql\n");
	$sth_tn = $dbh->prepare($sql);
	# and cache
	$adp->sth($cache_key_tn, $sth_tn);
    }
    # first insert the taxon node
    if($adp->verbose > 0) {
	$adp->debug(substr(ref($adp),rindex(ref($adp),"::")+2).
		    "::insert: ".
		    "binding column 1 to \"", $obj->ncbi_taxid,
		    "\" (ncbi_taxid)\n");
    }
    my $rv = $sth_t->execute($obj->ncbi_taxid);
    # we need the newly assigned primary key
    my $pk;
    if($rv) {
	$pk = $adp->dbcontext->dbi->last_id_value($dbh,
					    $self->sequence_name($node_table));
	# now insert binomial into the taxon name table
	if($adp->verbose > 0) {
	    $adp->debug(substr(ref($adp),rindex(ref($adp),"::")+2).
			"::insert: ".
			"binding columns 1;2;3 to \"",
			join(";",$pk,$obj->binomial("full"),"scientific name"),
			"\" ($fkname, name, name_class)\n");
	}
	$rv = $sth_tn->execute($pk, $obj->binomial("FULL"), "scientific name");
    }
    # if defined insert common_name into the taxon name table
    if($rv && $obj->common_name) {
	if($adp->verbose > 0) {
	    $adp->debug(substr(ref($adp),rindex(ref($adp),"::")+2).
			"::insert: ".
			"binding columns 1;2;3 to \"",
			join(";",$pk,$obj->common_name,"common name"),
			"\" ($fkname, name, name_class)\n");
	}
	$rv = $sth_tn->execute($pk, $obj->common_name(), "common name");
    }
    # done, return
    return $pk;
}

=head2 update_object

 Title   : update_object
 Usage   :
 Function:
 Example :
 Returns : The number of updated rows
 Args    : A Bio::DB::BioSQL::BasePersistenceAdaptor derived object
           (basically, it needs to implement dbh(), sth($key, $sth),
	    dbcontext(), and get_persistent_slots()).
	   The object to be updated.
           A reference to an array of foreign key objects; if any of those
           foreign key values is NULL (some foreign keys may be nullable),
           then give the class name.


=cut

sub update_object{
    my ($self,$adp,$obj,$fkobjs) = @_;

    $self->throw_not_implemented();

    # obtain the object's slots to be serialized
    my @slots = $adp->get_persistent_slots($obj);
    # get the UPDATE statement 
    # is it cached?
    my $cache_key = 'UPDATE '.ref($obj).' '.join(';',@slots);
    my $sth = $adp->sth($cache_key);
    # we need the slot map regardless of whether we need to construct the
    # SQL or not, because we need to know which slots do not map to a column
    # (indicated by them being mapped to undef)
    my $table = $self->table_name($adp);
    my $slotmap = $self->slot_attribute_map($table);
    $self->throw("no slot/attribute map for table $table") unless $slotmap;
    # if not cached, create SQL and prepare statement
    if(! $sth) {
	# construct UPDATE statement as straightforward SQL
	my @attrs = ();
	foreach my $slot (@slots) {
	    if(! exists($slotmap->{$slot})) {
		$self->throw("no mapping for slot $_ in slot-attribute map");
	    }
	    # we don't add a column nor a placeholder for unmapped slots
	    if($slotmap->{$slot} &&
	       (substr($slotmap->{$slot},0,2) ne '=>')) {
		push(@attrs, $slotmap->{$slot});
	    }
	}
	# foreign keys
	if($fkobjs) {
	    foreach (@$fkobjs) {
		my $fkattr = $self->foreign_key_name($_);
		push(@attrs, $fkattr);
	    }
	}
	my $ifnull = $adp->dbcontext->dbi->ifnull_sqlfunc();
	my $sql = "UPDATE $table SET " .
	    join(", ", map {"$_ = $ifnull\(?,$_\)";} @attrs) .
	    " WHERE " . $self->primary_key_name($table) . " = ?";
	$adp->debug("preparing UPDATE statement: $sql\n");
	$sth = $adp->dbh()->prepare($sql);
	# and cache
	$adp->sth($cache_key, $sth);
    }
    # bind paramater values
    my $slotvals = $adp->get_persistent_slot_values($obj, $fkobjs);
    if(@$slotvals != @slots) {
	$self->throw("number of slots must equal the number of values");
    }
    my $i = 0; # slots and slot values index
    my $j = 1; # column index
    while($i < @slots) {
	if($slotmap->{$slots[$i]} &&
	   (substr($slotmap->{$slots[$i]},0,2) ne '=>')) {
	    if($adp->verbose > 0) {
		$adp->debug(substr(ref($adp),rindex(ref($adp),"::")+2).
			    "::update: ".
			    "binding column $j to \"" .
			    $slotvals->[$i] . "\" ($slots[$i])\n");
	    }
	    $sth->bind_param($j, $slotvals->[$i]);
	    $j++;
	}
	$i++;
    }
    # bind foreign key values
    if($fkobjs) {
	foreach my $o (@$fkobjs) {
	    # If it's an object, the value to bind is the primary key. If it's
	    # numeric, the value is the number. Otherwise bind undef.
	    my $fk = ref($o) ?
		$o->primary_key() :
		$o =~ /^\d+$/ ? $o : undef;
	    if($adp->verbose > 0) {
		$adp->debug(substr(ref($adp),rindex(ref($adp),"::")+2).
			    "::update: ".
			    "binding column $j to \"$fk\" (FK to ".
			    $self->table_name($o) . ")\n");
	    }
	    $sth->bind_param($j, $fk);
	    $j++;
	}
    }
    # bind the primary key (which is in the WHERE clause)
    $sth->bind_param($j, $obj->primary_key());
    # execute
    my $rv = $sth->execute();
    if(! $rv) {
	$self->warn("update in ".ref($adp)." (driver) failed, values were (\"".
		    join("\",\"",@$slotvals)."\") ".
		    ($fkobjs ?
		     "FKs (".join(",",
				  map {
				      $_ && ref($_) ?
					  $_->primary_key() : "<NULL>";
				  } @$fkobjs).
		     ")\n" : "\n").
		    $sth->errstr);
    }
    # done, return
    return $rv;
}

=head2 _build_select_list

 Title   : _build_select_list
 Usage   :
 Function: Builds and returns the select list for an object query. The list
           contains those columns, in the right order, that are necessary to
           populate the object.
 Example :
 Returns : An array of strings (column names, not prefixed)
 Args    : The calling persistence adaptor.
           A reference to an array of foreign key entities (objects, class
           names, or adaptors) the object must attach.
           A reference to a hash table mapping entity names to aliases (if
           omitted, aliases will not be used, and SELECT columns can only be
           from one table)


=cut

sub _build_select_list{
    my ($self,$adp,$fkobjs,$entitymap) = @_;

    my @attrs = $self->SUPER::_build_select_list($adp,$fkobjs,$entitymap);
    # we need to massage the attribute list ...
    for(my $i = 0; $i < @attrs; $i++) {
	if($attrs[$i] =~ /ncbi_taxon_id/i) {
	    my $name_table = $self->table_name("Bio::Species");
	    my $node_table = $self->table_name("TaxonNode");
	    $attrs[$i] =~ s/$name_table/$node_table/;
	}
    }
    return @attrs;
}

1;
