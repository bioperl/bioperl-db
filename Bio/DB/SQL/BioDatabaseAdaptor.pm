
#
# BioPerl module for Bio::DB::SQL::BioDatabaseAdaptor
#
# Cared for by Ewan Birney <birney@ebi.ac.uk>
#
# Copyright Ewan Birney
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::DB::SQL::BioDatabaseAdaptor - DESCRIPTION of Object

=head1 SYNOPSIS

Give standard usage here

=head1 DESCRIPTION

Describe the object here

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

=head1 AUTHOR - Ewan Birney

Email birney@ebi.ac.uk

Describe contact details here

=head1 APPENDIX

The rest of the documentation details each of the object methods. Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::DB::SQL::BioDatabaseAdaptor;
use vars qw(@ISA);
use strict;

# Object preamble - inherits from Bio::Root::RootI

use Bio::DB::SQL::BaseAdaptor;


@ISA = qw(Bio::DB::SQL::BaseAdaptor);

# new() can be inherited from Bio::Root::RootI


=head2 fetch_by_name_store_if_needed

 Title   : fetch_by_name_store_if_needed
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub fetch_by_name_store_if_needed{
   my ($self,$name) = @_;

   my $id = $self->fetch_by_name($name);
   
   if( !defined $id || $id eq '' ) {
       $id = $self->store($name);
   }

   return $id

}


=head2 fetch_by_name

 Title   : fetch_by_name
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub fetch_by_name{
   my ($self,$name) = @_;

   my $sth = $self->prepare("select biodatabase_id from biodatabase where name = '$name'");
   $sth->execute;

   my ($id) = $sth->fetchrow_array();

   return $id;
}

=head2 store

 Title   : store
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub store{
   my ($self,$name) = @_;

   my $sth = $self->prepare("insert into biodatabase (biodatabase_id,name) values (NULL,'$name')");
   $sth->execute;
   $sth = $self->prepare("select LAST_INSERT_ID()");
   $sth->execute;
   my ($id) = $sth->fetchrow_array;

   return $id;
}
