

#
# BioPerl module for Bio::DB::PrimarySeq
#
# Cared for by Ewan Birney <birney@ebi.ac.uk>
#
# Copyright Ewan Birney
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::DB::PrimarySeq - DESCRIPTION of Object

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


package Bio::DB::PrimarySeq;
use vars qw($@ISA);
use strict;

# Object preamble - inherits from Bio::Root::RootI

use Bio::Root::RootI;


@ISA = qw(Bio::Root::RootI);
# new() can be inherited from Bio::Root::RootI


sub new {
    my ($class,$dbobj) = @_;

    my $self = {};
    bless $self,$class;

    my($primary_id,$display_id,$accession,$adaptor) = 
	$self->_rearrange([qw(PRIMARY DISPLAY ACCESSION ADAPTOR LENGTH)],@args);

    if( !defined $primary_id || !defined $display_id || !definded $accession || !defined $adaptor || !defined $length) {
	$self->throw("Not got one of the arguments in DB::PrimarySeq new");
    }

    $self->primary_id($primary_id);
    $self->display_id($display_id);
    $self->accession($accession);
    $self->adaptor($adaptor);
    $self->length($length);

    return $self;
}

=head2 primary_id

 Title   : primary_id
 Usage   : $obj->primary_id($newval)
 Function: 
 Example : 
 Returns : value of primary_id
 Args    : newvalue (optional)


=cut

sub primary_id{
   my ($obj,$value) = @_;
   if( defined $value) {
      $obj->{'primary_id'} = $value;
    }
    return $obj->{'primary_id'};

}

=head2 display_id

 Title   : display_id
 Usage   : $obj->display_id($newval)
 Function: 
 Example : 
 Returns : value of display_id
 Args    : newvalue (optional)


=cut

sub display_id{
   my ($obj,$value) = @_;
   if( defined $value) {
      $obj->{'display_id'} = $value;
    }
    return $obj->{'display_id'};

}

=head2 accession

 Title   : accession
 Usage   : $obj->accession($newval)
 Function: 
 Example : 
 Returns : value of accession
 Args    : newvalue (optional)


=cut

sub accession{
   my ($obj,$value) = @_;
   if( defined $value) {
      $obj->{'accession'} = $value;
    }
    return $obj->{'accession'};

}

=head2 adaptor

 Title   : adaptor
 Usage   : $obj->adaptor($newval)
 Function: 
 Example : 
 Returns : value of adaptor
 Args    : newvalue (optional)


=cut

sub adaptor{
   my ($obj,$value) = @_;
   if( defined $value) {
      $obj->{'adaptor'} = $value;
    }
    return $obj->{'adaptor'};

}

=head2 length

 Title   : length
 Usage   : $obj->length($newval)
 Function: 
 Example : 
 Returns : value of length
 Args    : newvalue (optional)


=cut

sub length{
   my ($obj,$value) = @_;
   if( defined $value) {
      $obj->{'length'} = $value;
    }
    return $obj->{'length'};

}

#
# methods
#

=head2 seq

 Title   : seq
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub seq{
   my ($self,@args) = @_;

   return $self->adaptor->get_seq_as_string($self->primary_id);
}

=head2 subseq

 Title   : subseq
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub subseq{
   my ($self,$start,$end) = @_;

   return $self->adaptor->get_subseq_as_string($self->primary_id,$start,$end);
}


