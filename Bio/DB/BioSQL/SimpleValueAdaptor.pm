# $Id$
#
# BioPerl module for Bio::DB::BioSQL::SimpleValueAdaptor
#
# Cared for by Hilmar Lapp <hlapp at gmx.net>
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

Bio::DB::BioSQL::SimpleValueAdaptor - DESCRIPTION of Object

=head1 SYNOPSIS

Give standard usage here

=head1 DESCRIPTION

SimpleValue DB adaptor 

=head1 FEEDBACK

=head2 Mailing Lists

User feedback is an integral part of the evolution of this
and other Bioperl modules. Send your comments and suggestions preferably
 to one of the Bioperl mailing lists.
Your participation is much appreciated.

  bioperl-l@bio.perl.org

=head2 Reporting Bugs

Report bugs to the Bioperl bug tracking system to help us keep track
 the bugs and their resolution.
 Bug reports can be submitted via email or the web:

  bioperl-bugs@bio.perl.org
  http://bio.perl.org/bioperl-bugs/

=head1 AUTHOR - Hilmar Lapp

Email hlapp at gmx.net

Describe contact details here

=head1 APPENDIX

The rest of the documentation details each of the object methods. Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::DB::BioSQL::SimpleValueAdaptor;
use vars qw(@ISA);
use strict;

# Object preamble 

use Bio::DB::BioSQL::BasePersistenceAdaptor;
use Bio::DB::BioSQL::TermAdaptor;
use Bio::DB::PersistentObjectI;
use Bio::Ontology::Term;
use Bio::Annotation::SimpleValue;

@ISA = qw(Bio::DB::BioSQL::TermAdaptor);


# new() is inherited and has caching turned on already (supposedly for terms)

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

    return ("tagname", "value");
}

=head2 get_persistent_slot_values

 Title   : get_persistent_slot_values
 Usage   :
 Function: Obtain the values for the slots returned by get_persistent_slots(),
           in exactly that order.

           The reason this method is here is that sometimes the actual slot
           values need to be post-processed to yield the value that gets
           actually stored in the database. E.g., slots holding arrays
           will need some kind of join function applied. Another example is if
           the method call needs additional arguments. Supposedly the
           adaptor for a specific interface knows exactly what to do here.

           Since there is also populate_from_row() the adaptor has full
           control over mapping values to a version that is actually stored.
 Example :
 Returns : A reference to an array of values for the persistent slots of this
           object. Individual values may be undef.
 Args    : The object about to be serialized.
           A reference to an array of foreign key objects if not retrievable 
           from the object itself.


=cut

sub get_persistent_slot_values {
    my ($self,$obj,$fkobjs) = @_;
    my @vals = ($obj->tagname(),
		$obj->value()
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

           An implementation may obtain the values either through the object
           to be serialized, or through the additional arguments. An
           implementation should also make sure that the order of foreign key
           objects returned is always the same.

           Note also that in order to indicate a NULL value for a nullable
           foreign key, either put an object returning undef from 
           primary_key(), or put the name of the class instead. DO NOT SIMPLY
           LEAVE IT OUT.

 Example :
 Returns : an array of Bio::DB::PersistentObjectI implementing objects
 Args    : The object about to be inserted or updated, or undef if the call
           is for a SELECT query. In the latter case return class or interface
           names that are mapped to the foreign key tables.
           Optionally, additional named parameters. A common parameter will
           be -fkobjs, with a reference to an array of foreign key objects
           that are not retrievable from the persistent object itself.

=cut

sub get_foreign_key_objects{
    my ($self,$obj,$fkobjs) = @_;
    my $term;

    if(ref($obj)) {
	$term = $self->_category_fk();
	$term->foreign_key_slot("Bio::Ontology::TermI::category");
    } else {
	$term = "Bio::Ontology::TermI::category";
    }
    return ($term);
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

    # we don't need to attach a category here, since it's a constant ...
    return $ok;
}

=head2 remove_children

 Title   : remove_children
 Usage   :
 Function: This method is to cascade deletes in maintained objects.

           We just return TRUE here.

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

           This implementation call populate_from_row() to do the real job.
 Example :
 Returns : An object, or undef, if the row contains no values
 Args    : A reference to an array of column values. The first column is the
           primary key, the other columns are expected to be in the order 
           returned by get_persistent_slots().
           Optionally, the object factory to be used for instantiating the
           proper class. The adaptor must be able to instantiate a default
           class if this value is undef.


=cut

sub instantiate_from_row{
    my ($self,$row,$fact) = @_;
    my $obj;

    if($row && @$row) {
	if($fact) {
	    $obj = $fact->create_object();
	} else {
	    $obj = Bio::Annotation::SimpleValue->new();
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
           A reference to an array of column values. The first column is the
           primary key, the other columns are expected to be in the order 
           returned by get_persistent_slots().


=cut

sub populate_from_row{
    my ($self,$obj,$rows) = @_;

    if(! ref($obj)) {
	$self->throw("\"$obj\" is not an object. Probably internal error.");
    }
    if($rows && @$rows) {
	$obj->tagname($rows->[1]) if $rows->[1];
	$obj->value($rows->[2]) if $rows->[2];
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
 Returns : A reference to a hash with the names of the object''s slots in the
           unique key as keys and their values as values.
 Args    : The object with those attributes set that constitute the chosen
           unique key (note that the class of the object will be suitable for
           the adaptor).
           A reference to an array of foreign key objects if not retrievable 
           from the object itself.


=cut

sub get_unique_key_query{
    my ($self,$obj,$fkobjs) = @_;
    my $uk_h = {};

    # UK for the tag of tag/value is the tag
    if($obj->tagname()) {
	$uk_h->{'tagname'} = $obj->tagname();
	my $cat = $self->_category_fk();
	if($cat) {
	    $uk_h->{'category'} = $cat->primary_key();
	}
    }
    
    return $uk_h;
}

=head2 _category_fk

 Title   : _category_fk
 Usage   : $obj->_category_fk($newval)
 Function: Get/set the category foreign key constant.

           This is a private method.
 Example : 
 Returns : value of _category_fk (a Bio::Ontology::TermI compliant object)
 Args    : new value (a Bio::Ontology::TermI compliant object, optional)


=cut

sub _category_fk{
    my ($self,$term) = @_;

    if( defined $term) {
	$self->{'_category_fk'} = $term;
    } else {
	if(! exists($self->{'_category_fk'})) {
	    $term = Bio::Ontology::Term->new(-name => "Annotation Tags");
	} else {
	    $term = $self->{'_category_fk'};
	}
	if(! $term->isa("Bio::DB::PersistentObjectI")) {
	    $term = $self->db()->create_persistent($term);
	    $self->{'_category_fk'} = $term;
	}
    }
    return $term;
}

=head1 Methods overriden from BasePersistenceAdaptor

=cut

=head2 remove

 Title   : remove
 Usage   : $objectstoreadp->remove($persistent_obj, @params)
 Function: Removes the persistent object from the datastore.
 Example :
 Returns : TRUE on success and FALSE otherwise
 Args    : The object to be removed, and optionally additional (named) 
           parameters.


=cut

sub remove{
    my ($self,$obj,@args) = @_;

    $self->throw("remove() not yet implemented in SimpleValueAdaptor()");
}

=head2 add_association

 Title   : add_assocation
 Usage   :
 Function: Stores the association between given objects in the datastore.

           We override this here to make sure the value slot gets stored in
           associations.
 Example :
 Returns : TRUE on success and FALSE otherwise
 Args    : Named parameters. At least the following must be recognized:
               -objs   a reference to an array of objects to be associated with
                       each other
               -values a reference to a hash the keys of which are abstract
                       column names and the values are values of those columns.
                       These columns are generally those other than
                       the ones for foreign keys to the entities to be
                       associated
               -obj_contexts optional, if given it denotes a reference to an
                       array of context keys (strings), which allow the
                       foreign key name to be determined through the
                       association map rather than through foreign_key_name().
                       This is necessary if more than one object of the same
                       type takes part in the association. The array must be
                       in the same order as -objs, and have the same number
                       of elements. Put "default" for objects for which there
                       are no multiple contexts.
  Caveats: Make sure you *always* give the objects to be associated in the
           same order.


=cut

sub add_association{
    my ($self,@args) = @_;
    my ($i);

    # get arguments
    my ($objs, $values) = $self->_rearrange([qw(OBJS VALUES)], @args);
    # have we been called in error? If so, be graceful and return an error.
    return undef unless $objs && @$objs;
    # figure out which one of the objects is the reference
    my $obj;
    my $svidx = 0;
    while($svidx < @$objs) {
	if($objs->[$svidx]->isa("Bio::Annotation::SimpleValue")) {
	    $obj = $objs->[$svidx];
	    last;
	}
	$svidx++;
    }
    # make sure we include the value for the association
    if($obj) {
	$values->{'value'} = $obj->value();
	if(! $obj->primary_key()) {
	    # this may happen as SimpleValue objects are sometimes created
	    # on the fly from more light-weight tag/value pairs
	    my $svobj = $self->find_by_unique_key($obj);
	    $obj->primary_key($svobj->primary_key()) if $svobj;
	}
    } else {
	$self->warn("unable to figure out the Bio::Annotation::SimpleValue ".
		    "object to associate with something, expect problems");
    }
    # pass on to the inherited impl.
    return $self->SUPER::add_association(@args);
}

=head2 find_by_primary_key

 Title   : find_by_primary_key
 Usage   : $objectstoreadp->find_by_primary_key($pk)
 Function: Locates the entry associated with the given primary key and
           initializes a persistent object with that entry.

           SimpleValues are not identifiable by primary key. It is suspicious
           if someone calls this method, so we throw an exception until we
           know better.
 Example :
 Returns : An instance of the class this adaptor adapts, represented by an
           object implementing Bio::DB::PersistentObjectI, or undef if no
           matching entry was found.
 Args    : The primary key.
           Optionally, the Bio::Factory::ObjectFactoryI compliant object
           factory to be used for instantiating the proper class. If the object
           does not implement Bio::Factory::ObjectFactoryI, it is assumed to
           be the object to be populated with the query results.


=cut

sub find_by_primary_key{
    my ($self,$dbid,$fact) = @_;

    $self->throw("SimpleValue annotations don't have a primary key.");
}


1;
