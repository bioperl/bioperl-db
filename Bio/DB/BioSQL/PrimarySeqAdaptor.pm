

#
# BioPerl module for Bio::DB::SQL::PrimarySeqAdaptor
#
# Cared for by Ewan Birney  <birney@ebi.ac.uk>
#
# Copyright Ewan Birney 
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::DB::SQL::PrimarySeqAdaptor - DESCRIPTION of Object

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


package Bio::DB::SQL::PrimarySeqAdaptor;
use vars qw(@ISA);
use strict;

use Bio::DB::SQL::BaseAdaptor;
use Bio::DB::PrimarySeq;

@ISA = qw(Bio::DB::SQL::BaseAdaptor);

# new inherieted from base adaptor.

=head2 fetch_by_dbID

 Title   : fetch_by_dbID
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub fetch_by_dbID{
   my ($self,$id) = @_;

   my $sth = $self->prepare("select en.display_id,en.accession,length(bs.biosequence_str),bs.molecule from bioentry en,biosequence bs where bs.bioentry_id = en.bioentry_id and bs.bioentry_id = $id");

   $sth->execute;

   my ($display,$acc,$len,$mol) = $sth->fetchrow_array;

   if( !defined $display ) {
       $self->throw("Bioentry id $id does not have a biosequence or bioentry ");
   }

   return Bio::DB::PrimarySeq->new( -primary_id => $id,
				    -display_id => $display,
				    -accession  => $acc,
				    -moltype    => $mol,
				    '-length'   => $len,
				    -adaptor    => $self);
   
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
   my ($self,$bioentry_id,$pseq) = @_;

   if( !defined $pseq || !ref $pseq || !$pseq->isa('Bio::PrimarySeqI') ) {
       $self->throw("Yikes. Don't have a primary seq to store $pseq");
   }
   my $mol='XXX';
   if (defined $pseq->moltype) {
       $mol=$pseq->moltype;
   }
   my $seq = $pseq->seq;
   my $sth = $self->prepare("insert into biosequence (biosequence_id,bioentry_id,biosequence_str,molecule) values (NULL,$bioentry_id,'$seq','$mol')");

   $sth->execute;

}


=head2 get_seq_as_string

 Title   : get_seq_as_string
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub get_seq_as_string{
   my ($self,$id) = @_;

   my $sth = $self->prepare("select biosequence_str from biosequence where bioentry_id = $id");

   $sth->execute;

   my ($str) = $sth->fetchrow_array;

   return $str;

}

=head2 get_subseq_as_string

 Title   : get_subseq_as_string
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub get_subseq_as_string{
   my ($self,$id,$start,$end) = @_;


   my $length = $end - $start +1;

   if( $start < 0 || $end < 0 ) {
       $self->throw("Bad start/end points $start,$end");
   }

   #print STDERR "Going to do select on $start to $end\n";

   my $sth = $self->prepare("select SUBSTRING(biosequence_str,$start,$length) from biosequence where bioentry_id = $id");

   $sth->execute;

   my ($str) = $sth->fetchrow_array;

   return $str;
}

=head2 get_description

 Title   : get_description
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub get_description{
   my ($self,$id) = @_;

   my $sth = $self->prepare("select description from bioentry_description where bioentry_id = $id");
   $sth->execute;

   my ($desc) = $sth->fetchrow_array;

   return $desc;
}

1;





