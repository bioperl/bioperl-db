# $Id$

#
# BioPerl module for Bio::DB::Annotation
#
# Cared for by Ewan Birney <birney@ebi.ac.uk>
#
# Copyright Ewan Birney
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::DB::Annotation - DESCRIPTION of Object

=head1 SYNOPSIS

Give standard usage here

=head1 DESCRIPTION

  DB bound annotation, lazy fetching

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


package Bio::DB::Annotation;
use vars qw(@ISA);
use strict;
use Bio::Root::Root;

@ISA = qw(Bio::Root::Root);

=head2 new

 Title   : new
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub new{
   my ($class,@args) = @_;

   my $self = bless {}, ref($class) || $class;

   my ($dbadp,$bioentry_id) = $self->_rearrange([qw(ADAPTOR 
						    BIOENTRY_ID)],@args);

   if( !defined $dbadp || !defined $bioentry_id) {
       $self->throw("Must have database adaptor and bioentry_id");
   }

   $self->_db_adaptor($dbadp);
   $self->_bioentry_id($bioentry_id);

   return $self;
}


=head2 get_Annotations

 Title   : get_Annotations
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub get_Annotations{
   my ($self,$type) = @_;

   $type = lc $type;
   if( $type eq 'comment' ) { 
       if( !defined $self->{'_comment'} ) {
	   my @array = $self->_db_adaptor->get_CommentAdaptor->fetch_by_bioentry_id($self->_bioentry_id);
	   $self->{'_comment'}= \@array;
       }
       return @{$self->{'_comment'}};       
   } elsif ($type eq 'reference' ) { 

       if( !defined $self->{'_references'} ) {
	   my @array = $self->_db_adaptor->get_ReferenceAdaptor->fetch_by_bioentry_id($self->_bioentry_id);
	   $self->{'_references'}= \@array;
       }
       
       return @{$self->{'_references'}};

   } elsif ($type eq 'dblink' ) {
       if( !defined $self->{'_db_link'} ) {
	   my @array = $self->_db_adaptor->get_DBLinkAdaptor->fetch_by_bioentry_id($self->_bioentry_id);
	   $self->{'_db_link'}= \@array;
       }
       
       return @{$self->{'_db_link'}};
   }
   return ();
}

=head2 each_Comment

 Title   : each_Comment
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub each_Comment{
   my ($self,@args) = @_;
   $self->warn("Deprecated: each_Comment is replaced with get_Annotations('comment')");
   return $self->get_Annotations('comment');
}

=head2 each_DBLink

 Title   : each_DBLink
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub each_DBLink{
   my ($self,@args) = @_;
   $self->warn("Deprecated: each_DBlink is replaced with get_Annotations('dblink')");
   return $self->get_Annotations('dblink');
}

=head2 each_Reference

 Title   : each_Reference
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub each_Reference{
   my ($self,@args) = @_;
   $self->warn("Deprecated: each_Reference is replaced with get_Annotations('reference')");
   return $self->get_Annotations('reference');
}


#
# Internal methods
# 

=head2 _bioentry_id

 Title   : _bioentry_id
 Usage   : $obj->_bioentry_id($newval)
 Function: 
 Example : 
 Returns : value of _bioentry_id
 Args    : newvalue (optional)


=cut

sub _bioentry_id{
   my ($obj,$value) = @_;
   if( defined $value) {
      $obj->{'_bioentry_id'} = $value;
    }
    return $obj->{'_bioentry_id'};

}

=head2 _db_adaptor

 Title   : _db_adaptor
 Usage   : $obj->_db_adaptor($newval)
 Function: 
 Example : 
 Returns : value of _db_adaptor
 Args    : newvalue (optional)


=cut

sub _db_adaptor{
   my ($obj,$value) = @_;
   if( defined $value) {
      $obj->{'_db_adaptor'} = $value;
    }
    return $obj->{'_db_adaptor'};

}

1;
