
#
# BioPerl module for Bio::DB::BioDatabasePSeqStream
#
# Cared for by Ewan Birney <birney@ebi.ac.uk>
#
# Copyright Ewan Birney
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::DB::BioDatabasePSeqStream - DESCRIPTION of Object

=head1 SYNOPSIS

Give standard usage here

=head1 DESCRIPTION

A Bio::DB::PrimarySeqStreamI implementing object for the DB::SQL database 

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


package Bio::DB::BioDatabasePSeqStream;
use vars qw(@ISA);
use strict;

# Object preamble - inherits from Bio::Root::RootI

use Bio::Root::RootI;

@ISA = qw(Bio::Root::RootI);
# new() can be inherited from Bio::Root::RootI

sub new {
    my ($class,@args) = @_;

    my $self = {};
    bless $self,$class;

    my($adaptor,$idlist) = $self->_rearrange(['ADAPTOR','IDLIST'],@args);
    
    if( !defined $adaptor ) {
	$self->throw("No adaptor!");
    }

    $self->_adaptor($adaptor);
    $self->{'_idlist'} = $idlist;
    
    return $self;
}

=head2 next_primary_seq

 Title   : next_primary_seq
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub next_primary_seq{
   my ($self) = @_;

   my $id = shift @{$self->{'_idlist'}};
   if( !defined $id ) {
       return undef;
   }

   return $self->_adaptor->fetch_by_dbID($id);
}

=head2 _adaptor

 Title   : _adaptor
 Usage   : $obj->_adaptor($newval)
 Function: 
 Example : 
 Returns : value of _adaptor
 Args    : newvalue (optional)


=cut

sub _adaptor{
   my ($obj,$value) = @_;
   if( defined $value) {
      $obj->{'_adaptor'} = $value;
    }
    return $obj->{'_adaptor'};

}



