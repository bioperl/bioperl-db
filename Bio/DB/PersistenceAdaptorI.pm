# $Id$
#
# BioPerl module for Bio::DB::PersistenceAdaptorI
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

Bio::DB::PersistenceAdaptorI - DESCRIPTION of Interface

=head1 SYNOPSIS

Give standard usage here

=head1 DESCRIPTION

This interface gives the base methods to be implemented by modules that
bridge persistent objects to and from their datastores.

The design choice mixes the strategy pattern with the factory pattern
(find_by_XXXX()).

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
  http://bioperl.org/bioperl-bugs/

=head1 AUTHOR - Hilmar Lapp

Email hlapp at gmx.net

Describe contact details here

=head1 CONTRIBUTORS

Additional contributors names and emails here

=head1 APPENDIX

The rest of the documentation details each of the object methods.
Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::DB::PersistenceAdaptorI;
use vars qw(@ISA);
use strict;
use Carp;
use Bio::Root::RootI;

@ISA = qw( Bio::Root::RootI );

=head2 create

 Title   : create
 Usage   : $objectstoreadp->create($obj, @fkobjs)
 Function: Creates the object as a persistent object in the datastore. This
           is equivalent to an insert.
 Example :
 Returns : A Bio::DB::PersistentObjectI implementing object wrapping the
           inserted object.
 Args    : The object to be inserted.
           Optionally, foreign key objects in case these cannot be obtained
           from the object itself.


=cut

sub create{
    my ($self,@args) = @_;
   
    $self->throw_not_implemented();
}

=head2 create_persistent

 Title   : create_persistent
 Usage   :
 Function: Takes the given object and turns it onto a PersistentObjectI
           implementing object. Returns the result. Does not actually create
           the object in a database.

           Calling this method is expected to have a recursive effect such
           that all children of the object, i.e., all slots that are objects
           themselves, are made persistent objects, too.
 Example :
 Returns : A Bio::DB::PersistentObjectI implementing object wrapping the
           passed object.
 Args    : An object to be made into a PersistentObjectI object, and the class
           of which suitable for this adaptor.
           Optionally, the class which actually implements wrapping the object
           to become a PersistentObjectI.


=cut

sub create_persistent{
    my ($self,@args) = @_;
   
    $self->throw_not_implemented();
}

=head2 store

 Title   : store
 Usage   : $objectstoreadp->store($persistent_obj,@fkobjs)
 Function: Updates the given persistent object in the datastore.

           Implementations should be flexible and delegate to create() if the
           primary_key() method of the object returns undef.
 Example :
 Returns : TRUE on success and FALSE otherwise
 Args    : The object to be updated, which must implement
           Bio::DB:PersistentObjectI.
           Optionally, foreign key objects in case these cannot be obtained
           from the object itself.


=cut

sub store{
    my ($self,@args) = @_;

    $self->throw_not_implemented();
}

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
    my ($self,@args) = @_;

    $self->throw_not_implemented();
}

=head2 find_by_primary_key

 Title   : find_by_primary_key
 Usage   : $popj = $objectstoreadp->find_by_primary_key($pk)
 Function: Locates the entry associated with the given primary key and
           initializes a persistent object with that entry.
 Example :
 Returns : An instance of the class this adaptor adapts, represented by an
           object implementing Bio::DB::PersistentObjectI, or undef if no
           matching entry was found.
 Args    : The primary key


=cut

sub find_by_primary_key{
    my ($self,@args) = @_;

    $self->throw_not_implemented();
}

=head2 find_by_unique_key

 Title   : find_by_unique_key
 Usage   :
 Function: Locates the entry matching the unique key attributes as set in the
           passed object, and populates a persistent object with this entry.
 Example :
 Returns : A Bio::DB::PersistentObjectI implementing object, with the
           attributes populated with values provided by the entry in the
           datastore, or undef if no matching entry was found. If one was found,
           the object returned will be the first argument if that implemented
           Bio::DB::PersistentObjectI already.
 Args    : The object with those attributes set that constitute the chosen
           unique key (note that the class of the object must be suitable for
           the adaptor).
           Additional attributes and values if required, passed as a reference
           to a hash map.


=cut

sub find_by_unique_key{
    my ($self,@args) = @_;

    $self->throw_not_implemented();
}

1;
