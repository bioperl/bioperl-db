
#
# BioPerl module for Bio::DB::BioSeqDatabase
#
# Cared for by Ewan Birney <birney@ebi.ac.uk>
#
# Copyright Ewan Birney
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::DB::BioSeqDatabase - DESCRIPTION of Object

=head1 SYNOPSIS

Give standard usage here

=head1 DESCRIPTION

Database mediator between Bio::DB::SeqI interfaces and Bio::DB::SQL implementation 

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


package Bio::DB::BioSeqDatabase;
use vars qw(@ISA);
use Bio::DB::BioDatabasePSeqStream;
use strict;

# Object preamble - inherits from Bio::Root::RootI

use Bio::DB::SeqI;


@ISA = qw(Bio::DB::SeqI);
# new() can be inherited from Bio::Root::RootI

sub new {
    my ($class,@args) = @_;

    my $self = {};
    bless $self,$class;

    my($adaptor,$dbid) = $self->_rearrange(['ADAPTOR','DBID'],@args);
    
    if( !defined $adaptor) {
      $self->throw("No BioDatabase adaptor!");
    }
    elsif (! defined $dbid) {
      $self->throw("No database id given!");
    }

    $self->_adaptor($adaptor);
    $self->_dbid($dbid);
    
    return $self;
}


=head1 Methods inherieted from Bio::DB::RandomAccessI

=head2 get_Seq_by_id

 Title   : get_Seq_by_id
 Usage   : $seq = $db->get_Seq_by_id('ROA1_HUMAN')
 Function: Gets a Bio::Seq object by its name
 Returns : a Bio::Seq object
 Args    : the id (as a string) of a sequence
 Throws  : "id does not exist" exception


=cut

sub get_Seq_by_id {
    my ($self,$id) = @_;

    return $self->_adaptor->fetch_Seq_by_display_id($self->_dbid,$id);
}


=head2 get_Seq_by_acc

 Title   : get_Seq_by_acc
 Usage   : $seq = $db->get_Seq_by_acc('X77802');
 Function: Gets a Bio::Seq object by accession number
 Returns : A Bio::Seq object
 Args    : accession number (as a string)
 Throws  : "acc does not exist" exception


=cut

sub get_Seq_by_acc {
    my ($self,$acc) = @_;

    return $self->_adaptor->fetch_Seq_by_accession($self->_dbid,$acc);
}



=head1 Methods [that were] specific for Bio::DB::SeqI

=head2 get_PrimarySeq_stream

 Title   : get_PrimarySeq_stream
 Usage   : $stream = get_PrimarySeq_stream
 Function: Makes a Bio::DB::SeqStreamI compliant object
           which provides a single method, next_primary_seq
 Returns : Bio::DB::SeqStreamI
 Args    : none


=cut

sub get_PrimarySeq_stream{
   my ($self) = @_;

   my @array = $self->get_all_primary_ids;

   my $stream = Bio::DB::BioDatabasePSeqStream->new( -adaptor => $self->_adaptor->db->get_PrimarySeqAdaptor,
						     -idlist => \@array);

   return $stream;

}

=head2 get_all_primary_ids

 Title   : get_all_ids
 Usage   : @ids = $seqdb->get_all_primary_ids()
 Function: gives an array of all the primary_ids of the 
           sequence objects in the database. These
           maybe ids (display style) or accession numbers
           or something else completely different - they
           *are not* meaningful outside of this database
           implementation.
 Example :
 Returns : an array of strings
 Args    : none


=cut

sub get_all_primary_ids{
   my ($self,@args) = @_;

   return $self->_adaptor->list_bioentry_ids($self->_dbid);
}


=head2 get_Seq_by_primary_id

 Title   : get_Seq_by_primary_id
 Usage   : $seq = $db->get_Seq_by_primary_id($primary_id_string);
 Function: Gets a Bio::Seq object by the primary id. The primary
           id in these cases has to come from $db->get_all_primary_ids.
           There is no other way to get (or guess) the primary_ids
           in a database.

           The other possibility is to get Bio::PrimarySeqI objects
           via the get_PrimarySeq_stream and the primary_id field
           on these objects are specified as the ids to use here.
 Returns : A Bio::Seq object
 Args    : accession number (as a string)
 Throws  : "acc does not exist" exception


=cut

sub get_Seq_by_primary_id {
   my ($self,$id) = @_;

   return $self->_adaptor->db->get_SeqAdaptor->fetch_by_dbID($id);
}



=head2 name

 Title   : name
 Usage   : $obj->name($newval)
 Function: 
 Example : 
 Returns : value of name
 Args    : newvalue (optional)


=cut

sub name{
   my ($obj,$value) = @_;
   if( defined $value) {
      $obj->{'name'} = $value;
    }
    return $obj->{'name'};

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

=head2 _dbid

 Title   : _dbid
 Usage   : $obj->_dbid($newval)
 Function: 
 Example : 
 Returns : value of _dbid
 Args    : newvalue (optional)


=cut

sub _dbid{
   my ($obj,$value) = @_;
   if( defined $value) {
      $obj->{'_dbid'} = $value;
    }
    return $obj->{'_dbid'};

}



