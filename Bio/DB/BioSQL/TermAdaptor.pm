# $Id$
#
# BioPerl module for Bio::DB::BioSQL::TermAdaptor
#
# Cared for by Hilmar Lapp <hlapp at gmx.net>
#
# (c) Ewan Birney <birney@ebi.ac.uk>, 2002.
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

Bio::DB::BioSQL::TermAdaptor - DESCRIPTION of Object

=head1 SYNOPSIS

Give standard usage here

=head1 DESCRIPTION

Term DB adaptor 

=head1 FEEDBACK

=head2 Mailing Lists

User feedback is an integral part of the evolution of this
and other Bioperl modules. Send your comments and suggestions preferably
 to one of the Bioperl mailing lists.
Your participation is much appreciated.

  bioperl-l@bioperl.org

=head2 Reporting Bugs

Report bugs to the Bioperl bug tracking system to help us keep track
 the bugs and their resolution.
 Bug reports can be submitted via email or the web:

  bioperl-bugs@bio.perl.org
  http://bugzilla.bioperl.org/

=head1 AUTHOR - Ewan Birney, Hilmar Lapp

Email birney@ebi.ac.uk
Email hlapp at gmx.net

Describe contact details here

=head1 APPENDIX

The rest of the documentation details each of the object methods. Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::DB::BioSQL::TermAdaptor;
use vars qw(@ISA);
use strict;

# Object preamble 

use Bio::DB::BioSQL::BasePersistenceAdaptor;
use Bio::DB::PersistentObjectI;
use Bio::Ontology::Term;

@ISA = qw(Bio::DB::BioSQL::BasePersistenceAdaptor);


=head2 new

 Title   : new
 Usage   :
 Function: Instantiates the persistence adaptor.
 Example :
 Returns : 
 Args    :


=cut

sub new{
   my ($class,@args) = @_;

   # we want to enable object caching
   push(@args, "-cache_objects", 1) unless grep { /cache_objects/i; } @args;
   my $self = $class->SUPER::new(@args);

   return $self;
}


=head2 get_persistent_slots

 Title   : get_persistent_slots
 Usage   :
 Function: Get the slots of the object that map to attributes in its respective
           entity in the datastore.

           Slots should be methods callable without an argument.

 Example :
 Returns : an array of method names constituting the serializable slots
 Args    : the object about to be inserted or updated


=cut

sub get_persistent_slots{
    my ($self,@args) = @_;

    return ("identifier", "name", "definition","is_obsolete");
}

=head2 get_persistent_slot_values

 Title   : get_persistent_slot_values
 Usage   :
 Function: Obtain the values for the slots returned by get_persistent_slots(),
           in exactly that order.

           The reason this method is here is that sometimes the actual
           slot values need to be post-processed to yield the value
           that gets actually stored in the database. E.g., slots
           holding arrays will need some kind of join function
           applied. Another example is if the method call needs
           additional arguments. Supposedly the adaptor for a specific
           interface knows exactly what to do here.

           Since there is also populate_from_row() the adaptor has
           full control over mapping values to a version that is
           actually stored.

 Example :
 Returns : A reference to an array of values for the persistent slots of this
           object. Individual values may be undef.
 Args    : The object about to be serialized.
           A reference to an array of foreign key objects if not retrievable 
           from the object itself.


=cut

sub get_persistent_slot_values {
    my ($self,$obj,$fkobjs) = @_;
    my @vals = ($obj->identifier(),
		$obj->name(),
		$obj->definition(),
		$obj->is_obsolete() ? 'X' : undef
		);
    return \@vals;
}

=head2 get_foreign_key_objects

 Title   : get_foreign_key_objects
 Usage   :
 Function: Gets the objects referenced by this object, and which therefore need
           to be referenced as foreign keys in the datastore.

           Note that the objects are expected to implement
           Bio::DB::PersistentObjectI.

           An implementation may obtain the values either through the
           object to be serialized, or through the additional
           arguments. An implementation should also make sure that the
           order of foreign key objects returned is always the same.

           Note also that in order to indicate a NULL value for a
           nullable foreign key, either put an object returning undef
           from primary_key(), or put the name of the class
           instead. DO NOT SIMPLY LEAVE IT OUT.

 Example :
 Returns : an array of Bio::DB::PersistentObjectI implementing objects
 Args    : The object about to be inserted or updated, or undef if the call
           is for a SELECT query. In the latter case return class or interface
           names that are mapped to the foreign key tables.

           Optionally, additional named parameters. A common parameter
           will be -fkobjs, with a reference to an array of foreign
           key objects that are not retrievable from the persistent
           object itself.

=cut

sub get_foreign_key_objects{
    my ($self,$obj,$fkobjs) = @_;
    my $ont;

    if(ref($obj) && $obj->ontology()) {
	$ont = $obj->ontology();
    } else {
	$ont = "Bio::Ontology::OntologyI";
    }
    return ($ont);
}

=head2 attach_foreign_key_objects

 Title   : attach_foreign_key_objects
 Usage   :
 Function: Attaches foreign key objects to the given object as far as
           necessary.

           This method is called after find_by_XXX() queries, not for INSERTs
           or UPDATEs.

 Example :
 Returns : TRUE on success, and FALSE otherwise.
 Args    : The object to which to attach foreign key objects.
           A reference to an array of foreign key values, in the order of
           foreign keys returned by get_foreign_key_objects().


=cut

sub attach_foreign_key_objects{
    my ($self,$obj,$fks) = @_;
    my $ok = 1;
    
    if($fks && @$fks) {
	my $ont = $self->_ont_adaptor->find_by_primary_key($fks->[0]);
	$obj->ontology($ont) if $ont;
	$ok = $ont && $ok;
    }
    return $ok;
}

=head2 store_children

 Title   : store_children
 Usage   :
 Function: Inserts or updates the child entities of the given object in the 
           datastore.

           The implementation can assume that all of the child objects
           are already Bio::DB::PersistentObjectI.

           Ontology terms have synonyms and dbxrefs as children.

 Example :
 Returns : TRUE on success, and FALSE otherwise
 Args    : The Bio::DB::PersistentObjectI implementing object for which the
           child objects shall be made persistent.
           A reference to an array of foreign key values, in the order of
           foreign keys returned by get_foreign_key_objects().


=cut

sub store_children{
    my ($self,$obj,$fkobjs) = @_;
    my $ok = 1;

    # we possibly have synonyms to store
    foreach my $syn ($obj->get_synonyms()) {
	$ok = $self->store_synonym($obj,$syn) && $ok;
    }
    # we also possibly have db-xrefs to store
    foreach my $dbl ($obj->get_dblinks()) {
	$dbl = $dbl->create() unless $dbl->primary_key();
	$ok = $dbl && $ok;
	$dbl->adaptor->add_association(-objs => [$obj, $dbl]);
    }
    # done
    return $ok;
}

=head2 attach_children

 Title   : attach_children
 Usage   :
 Function: Possibly retrieve and attach child objects of the given object.

           This is needed when whole object trees are supposed to be
           built when a base object is queried for and returned. An
           example would be Bio::SeqI objects and all the annotation
           objects that hang off of it.

           This is called by the find_by_XXXX() methods once the base
           object has been built.

           An ontology term has synonyms and dbxrefs as children.

 Example :
 Returns : TRUE on success, and FALSE otherwise.
 Args    : The object for which to find and to which to attach the child
           objects.


=cut

sub attach_children{
    my ($self,$obj) = @_;
    my $ok = 1;

    # get and attach the dbxrefs
    my $dbladp = $self->db->get_object_adaptor("Bio::Annotation::DBLink");
    my $qres = $dbladp->find_by_association(-objs => [$obj,$dbladp]);
    while(my $dbl = $qres->next_object()) {
	$obj->add_dblink($dbl);
    }
    # retrieve the synonyms (synonyms aren't objects in their own right
    # in bioperl - although they could be)
    $ok = $self->get_synonyms($obj) && $ok;
    # done
    return $ok;
}

=head2 remove_children

 Title   : remove_children
 Usage   :
 Function: This method is to cascade deletes in maintained objects.


 Example :
 Returns : TRUE on success and FALSE otherwise
 Args    : The persistent object that was just removed from the database.
           Additional (named) parameter, as passed to remove().


=cut

sub remove_children{
    return 1;
}

=head2 instantiate_from_row

 Title   : instantiate_from_row
 Usage   :
 Function: Instantiates the class this object is an adaptor for, and populates
           it with values from columns of the row.

           This implementation calls populate_from_row() to do the
           real job.

 Example :
 Returns : An object, or undef, if the row contains no values
 Args    : A reference to an array of column values. The first column is the
           primary key, the other columns are expected to be in the order 
           returned by get_persistent_slots().

           Optionally, the object factory to be used for instantiating
           the proper class. The adaptor must be able to instantiate a
           default class if this value is undef.


=cut

sub instantiate_from_row{
    my ($self,$row,$fact) = @_;
    my $obj;

    if($row && @$row) {
	if($fact) {
	    $obj = $fact->create_object();
	} else {
	    $obj = Bio::Ontology::Term->new();
	}
	$self->populate_from_row($obj, $row);
    }
    return $obj;
}

=head2 populate_from_row

 Title   : populate_from_row
 Usage   :
 Function: Instantiates the class this object is an adaptor for, and populates
           it with values from columns of the row.

 Example :
 Returns : An object, or undef, if the row contains no values
 Args    : The object to be populated.

           A reference to an array of column values. The first column
           is the primary key, the other columns are expected to be in
           the order returned by get_persistent_slots().


=cut

sub populate_from_row{
    my ($self,$obj,$rows) = @_;

    if(! ref($obj)) {
	$self->throw("\"$obj\" is not an object. Probably internal error.");
    }
    if($rows && @$rows) {
	$obj->identifier($rows->[1]) if $rows->[1];
	$obj->name($rows->[2]) if $rows->[2];
	$obj->definition($rows->[3]) if $rows->[3];
	$obj->is_obsolete($rows->[4]) if $rows->[4];
	if($obj->isa("Bio::DB::PersistentObjectI")) {
	    $obj->primary_key($rows->[0]);
	}
	return $obj;
    }
    return undef;
}

=head2 get_unique_key_query

 Title   : get_unique_key_query
 Usage   :
 Function: Obtain the suitable unique key slots and values as determined by the
           attribute values of the given object and the additional foreign
           key objects, in case foreign keys participate in a UK. 

 Example :
 Returns : One or more references to hash(es) where each hash
           represents one unique key, and the keys of each hash
           represent the names of the object's slots that are part of
           the particular unique key and their values are the values
           of those slots as suitable for the key.
 Args    : The object with those attributes set that constitute the chosen
           unique key (note that the class of the object will be suitable for
           the adaptor).
           A reference to an array of foreign key objects if not retrievable 
           from the object itself.


=cut

sub get_unique_key_query{
    my ($self,$obj,$fkobjs) = @_;
    my $uk_h = {};

    # UKs for ontology terms are identifier and (name,ontology)
    if($obj->identifier()) {
	$uk_h->{'identifier'} = $obj->identifier();
    } elsif($obj->name()) {
	$uk_h->{'name'} = $obj->name();
	if(my $ont = $obj->ontology()) {
	    if($ont->isa("Bio::DB::PersistentObjectI")) {
		$ont->create() unless $ont->primary_key();
	    } else {
		$ont = $self->_ont_adaptor->find_by_unique_key($ont);
	    }
	    $uk_h->{'ontology'} = $ont->primary_key() if $ont;
	}
    }
    
    return $uk_h;
}

=head1 Methods overriden from BasePersistenceAdaptor

=cut

=head1 Public methods specific to this module

=cut

=head2 store_synonym

 Title   : store_synonym
 Usage   :
 Function: Stores a synonym for an ontology term.
 Example :
 Returns : TRUE on success, and FALSE otherwise.
 Args    : The persistent term object for which to store the synonym
           (a Bio::DB::PersistentObjectI compliant object with defined
           primary key).
           The synonym to store (a scalar). 


=cut

sub store_synonym{
    my ($self,$obj,$syn) = @_;
    # do the error checking right here
    $obj->isa("Bio::DB::PersistentObjectI") ||
	$self->throw("$obj is not a persistent object. Bummer.");
    $obj->primary_key ||
	$self->throw("primary key not defined - cannot store synonym without");
    # insert
    my $rv = $self->dbd->store_synonym($self,$obj,$syn);
    # done
    return $rv;
}

=head2 get_synonyms

 Title   : get_synonyms
 Usage   :
 Function: Retrieves the synonyms for an ontology term and adds them
           the term's synonyms.
 Example :
 Returns : TRUE on success, and FALSE otherwise.
 Args    : The persistent term object for which to retrieve the synonyms
           (a Bio::DB::PersistentObjectI compliant object with defined
           primary key).


=cut

sub get_synonyms{
    my ($self,$obj) = @_;
    # do the error checking right here
    $obj->isa("Bio::DB::PersistentObjectI") ||
	$self->throw("$obj is not a persistent object. Bummer.");
    $obj->primary_key ||
	$self->throw("primary key not defined - cannot get synonyms without");
    # retrieve and add
    my $rv = $self->dbd->get_synonyms($self,$obj);
    # done
    return $rv;
}

=head1 Private methods

  These are mostly convenience and/or shorthand methods.

=cut

=head2 _ont_adaptor

 Title   : _ont_adaptor
 Usage   : $obj->_ont_adaptor($newval)
 Function: Get/set the ontology persistence adaptor. 
 Example : 
 Returns : value of _ont_adaptor (a Bio::DB::PersistenceAdaptorI object)
 Args    : on set, new value (a Bio::DB::PersistenceAdaptorI object
           or undef, optional)


=cut

sub _ont_adaptor{
    my $self = shift;

    return $self->{'_ont_adaptor'} = shift if @_;
    if(! exists($self->{'_ont_adaptor'})) {
	$self->{'_ont_adaptor'} =
	    $self->db->get_object_adaptor("Bio::Ontology::OntologyI");
    }
    return $self->{'_ont_adaptor'};
}

1;
