

#
# BioPerl module for Bio::DB::SQL::SeqAdaptor
#
# Cared for by Ewan Birney <birney@ebi.ac.uk>
#
# Copyright Ewan Birney
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::DB::SQL::SeqAdaptor - DESCRIPTION of Object

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


package Bio::DB::SQL::SeqAdaptor;
use vars qw(@ISA);
use strict;


use Bio::DB::Seq;
use Bio::DB::SQL::BaseAdaptor;


@ISA = qw(Bio::DB::SQL::BaseAdaptor);

# new is from Bio::DB::SQL::Adaptor

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

   my $sth = $self->prepare("select en.display_id,en.accession,length(bs.biosequence_str) from bioentry en,biosequence bs where bs.bioentry_id = en.bioentry_id and bs.bioentry_id = $id");

   $sth->execute;

   my ($display,$acc,$len) = $sth->fetchrow_array;

   if( !defined $display ) {
       $self->throw("Bioentry id $id does not have a biosequence or bioentry ");
   }

   return Bio::DB::Seq->new( -primary_id => $id,
			     -display_id => $display,
			     -accession  => $acc,
			     '-length'     => $len,
			     -adaptor    => $self);
   

}

=head2 fetch_by_db_and_accession

 Title   : fetch_by_db_and_accession
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub fetch_by_db_and_accession{
   my ($self,$db,$accession) = @_;

   my $sth = $self->prepare("select en.bioentry_id from bioentry en, biodatabase biodb where biodb.name = '$db' AND en.biodatabase_id = biodb.biodatabase_id AND en.accession = '$accession'");
   $sth->execute;

   my ($enid) = $sth->fetchrow_array();

   if( defined $enid ) {
       # this is not well optimised. We could share common object building code here.
       return $self->fetch_by_dbID($enid);
   } else {
       $self->throw("Unable to retrieve sequence with $db and $accession");
   }
   
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
   my ($self,$dbid,$seq) = @_;

   if( !defined $seq || !ref $seq || !$seq->isa("Bio::SeqI") ) {
       $self->throw("$seq is not a Bio::SeqI!");
   }

   # simple store at the moment - 
   my $did       = $seq->id;
   my $accession = $seq->accession;
   my $version   = $seq->seq_version;
   if( !defined $version ) {
       $version = 0;
   }

   if( !defined $did || !defined $accession ) {
       $self->throw("no display id ($did) or no accession ($accession). Cannot process");
   }

   my $sth = $self->prepare("insert into bioentry (biodatabase_id,bioentry_id,display_id,accession,entry_version) values ($dbid,NULL,'$did','$accession',$version)");
   $sth->execute;
   $sth = $self->prepare("select LAST_INSERT_ID()");
   $sth->execute;
   my($id) = $sth->fetchrow_array();

   $self->db->get_PrimarySeqAdaptor->store($id,$seq->primary_seq);

   my $desc = $seq->desc;
   $desc =~ s/\'/\\\'/g;
   if( defined $seq->desc && $seq->desc ne '' ) {
       $sth = $self->prepare("insert into bioentry_description (bioentry_id,description) VALUES ($id,'$desc')");
       $sth->execute;
   }


   my $species = $seq->species;

   if( defined $species ) {
       my $species_id = $self->db->get_SpeciesAdaptor->store_if_needed($species);
       $sth = $self->prepare("insert into bioentry_taxa (bioentry_id,taxa_id) VALUES ($id,$species_id)");
       $sth->execute;
   }   

   my $rank = 1;
   my $adp  = $self->db->get_SeqFeatureAdaptor();

   foreach my $sf ( $seq->top_SeqFeatures ) {
       $adp->store($sf,$rank,$id);
   }

   $rank = 1;
   $adp = $self->db->get_CommentAdaptor();
   foreach my $comment ( $seq->annotation->each_Comment ) {
       $adp->store($comment,$rank,$id);
   }

   $adp = $self->db->get_DBLinkAdaptor();
   foreach my $dblink ( $seq->annotation->each_DBLink ) {
       $adp->store($dblink,$id);
   }

}

=head2 get_taxa_id

 Title   : get_taxa_id
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub get_taxa_id{
   my ($self,$bioentry_id) = @_;

   my $sth = $self->prepare("select taxa_id from bioentry_taxa where bioentry_id = $bioentry_id");
   $sth->execute();

   my ($taxa) = $sth->fetchrow_array();
   return $taxa;
}

