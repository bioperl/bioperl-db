
#
# BioPerl module for Bio::DB::SQL::SeqFeatureAdaptor
#
# Cared for by Ewan Birney <birney@ebi.ac.uk>
#
# Copyright Ewan Birney
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::DB::SQL::SeqFeatureAdaptor - DESCRIPTION of Object

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


package Bio::DB::SQL::SeqFeatureAdaptor;
use vars qw(@ISA);
use strict;

# Object preamble - inherits from Bio::Root::RootI

use Bio::DB::SQL::BaseAdaptor;
use Bio::SeqFeature::Generic;

@ISA = qw(Bio::DB::SQL::BaseAdaptor);

# new is inherieted


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

   my $generic = Bio::SeqFeature::Generic->new();

   # first pick out the central feature information

   my $sth = $self->prepare("select k.key_name,s.source_name from seqfeature f,seqfeature_key k,seqfeature_source s where f.seqfeature_key_id = k.seqfeature_key_id and f.seqfeature_source_id = s.seqfeature_source_id and f.seqfeature_id = $id");
   $sth->execute();

   my ($key,$source) = $sth->fetchrow_array();

   $generic->primary_tag($key);
   $generic->source_tag($source);

   my $loc = $self->db->get_SeqLocationAdaptor->fetch_by_dbID($id);
   $generic->location($loc);

   $sth = $self->prepare("select q.qualifier_name,qv.qualifier_value from seqfeature_qualifier q,seqfeature_qualifier_value qv where q.seqfeature_qualifier_id = qv.seqfeature_qualifier_id and qv.seqfeature_id = $id");
   $sth->execute();
   

   while( my $arrayref = $sth->fetchrow_arrayref ) {
       my ($name,$value) = @{$arrayref};
       $generic->add_tag_value($name,$value);
   }

   return $generic;
}

=head2 fetch_by_bioentry_id

 Title   : fetch_by_bioentry_id
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub fetch_by_bioentry_id{
   my ($self,$bioentry_id) = @_;

   # yes - not optimised. We could removed quite a few nested gets here
   my $sth = $self->prepare("select seqfeature_id from seqfeature where bioentry_id = $bioentry_id");
   $sth->execute;

   my @out;
   while( my $arrayref = $sth->fetchrow_arrayref )  {
       my ($sf_id) = @{$arrayref};
       push(@out,$self->fetch_by_dbID($sf_id));
   }

   return @out;
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
   my ($self,$feature,$rank,$bioentryid) = @_;

   if( !defined $bioentryid ) {
       $self->throw("Must store a seqfeature with a rank and bioentry id");
   }

   my $keyid = $self->db->get_SeqFeatureKeyAdaptor->store_if_needed($feature->primary_tag);
   my $sourceid = $self->db->get_SeqFeatureSourceAdaptor->store_if_needed($feature->source_tag);

   my $sth = $self->prepare("insert into seqfeature (seqfeature_id,bioentry_id,seqfeature_key_id,seqfeature_source_id,seqfeature_rank) VALUES (NULL,$bioentryid,$keyid,$sourceid,$rank)");

   $sth->execute();
   my ($last_id) = $sth->{'mysql_insertid'};

   if( !defined $last_id ) {
       $self->throw("Dont have last insert id...");
   }

   $self->db->get_SeqLocationAdaptor->store($feature->location,$last_id);

   my $adp = $self->db->get_SeqFeatureQualifierAdaptor();

   foreach my $tag ( $feature->all_tags() ) {
       my $qid = $adp->store_if_needed($tag);

       # placeholder would be more efficient here
       my $qrank = 1;
       foreach my $value ( $feature->each_tag_value($tag) ) {
	   $value =~ s/\'/\\\'/g;
	   $sth= $self->prepare("INSERT into seqfeature_qualifier_value (seqfeature_id,seqfeature_qualifier_id,qualifier_value,seqfeature_qualifier_rank) VALUES ($last_id,$qid,'$value',$rank)");
	   $sth->execute;
	   $rank++;
       }
   }

}




=head2 remove_by_bioentry_id

 Title   : remove_by_bioentry_id
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub remove_by_bioentry_id{
   my ($self) = shift;
   
   my ($be) = join ",", @_; 

   	my $sth = $self->prepare("select seqfeature_id from seqfeature where bioentry_id IN ($be)");
   	$sth->execute;
	my @sf = $sth->fetchrow_array;
	
	if (@sf) {
		my $counter = 1; 
	}
	else {
		return 0; 
	}
	
	while (my $a = $sth->fetchrow_array) {
		unshift @sf, $a; 
	}
	
	return $self->remove_by_dbID(@sf); 
}

=head2 remove_by_dbID

 Title   : remove_by_dbID
 Usage   : 
 Function: 
 Example : 
 Returns : 
 Args    : @dbID - an array of seqfeature identifiers (seqfeature.seqfeature_id)


=cut

sub remove_by_dbID{
	my ($self) = shift; 
	my ($sf) = join (",", @_); 
	
	my $sth = $self->prepare("DELETE FROM seqfeature WHERE seqfeature_id IN($sf)");
	$sth->execute();
	$sth->finish;	
	
	
	$self->db->get_SeqLocationAdaptor->remove_by_dbID(@_); 
	
 	$self->db->get_SeqFeatureSourceAdaptor->_clean_orphans; 
 	$self->db->get_SeqFeatureKeyAdaptor->_clean_orphans; 
 
	
	$sth = $self->prepare("DELETE FROM seqfeature_qualifier_value WHERE seqfeature_id IN($sf)");
	$sth->execute();
	$self->db->get_SeqFeatureQualifierAdaptor->_clean_orphans; 

	
	return ++$#_; 	
}
