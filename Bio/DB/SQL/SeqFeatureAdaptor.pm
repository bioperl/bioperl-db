
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

sub _table {"seqfeature"}

# new is inherieted


=head2 fetch_by_dbIDs

 Title   : fetch_by_dbIDs
 Usage   :
 Function:
 Example :
 Returns :
 Args    :

=cut

sub fetch_by_dbIDs {
   my ($self,$idarrayref) = @_;

   my $sfh = {};
   # accept scalars
   my @ids = ref($idarrayref) ? @$idarrayref : ($idarrayref);
   my $idjoin = join(",", @ids);

   # first pick out the central feature information
   my @rows =
     $self->selectall("seqfeature f,ontology_term k,seqfeature_source s",
                      "f.seqfeature_key_id = k.ontology_term_id and f.seqfeature_source_id = s.seqfeature_source_id and f.seqfeature_id in ($idjoin)",
                      "f.seqfeature_id,k.term_name,s.source_name",
                     );
   my @qualrows =
     $self->selectall("ontology_term t,seqfeature_qualifier_value qv",
                      "t.ontology_term_id = qv.ontology_term_id and qv.seqfeature_id in ($idjoin)",
                      "qv.seqfeature_id, t.term_name,qv.qualifier_value"
                     );

   my $loc_by_sfid =
     $self->db->get_SeqLocationAdaptor->fetch_by_dbIDs(\@ids);
   foreach my $row (@rows) {
       my $generic = Bio::SeqFeature::Generic->new();
       my $sfid = $row->{seqfeature_id};
       $sfh->{$sfid} = $generic;
       my ($key,$source) = ($row->{term_name}, $row->{source_name});

       $generic->primary_tag($key);
       $generic->source_tag($source);

       my @q = grep { $_->{seqfeature_id} == $sfid } @qualrows;
       foreach my $qh (@q) {
#           die "$qh->{qualifier_name}= $qh->{qualifier_value}\n";
           $generic->add_tag_value($qh->{term_name},
                                   $qh->{qualifier_value});
       }
   }

   foreach my $sfid (@ids) {
       my $sf = $sfh->{$sfid};
       $self->throw("no such sf as $sfid") unless $sf;
       my $loc = $loc_by_sfid->{$sfid};
       $self->throw("no loc for $sfid") unless $loc;
       $sf->location($loc);
   }

   return $sfh;
}

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

   my $sfh = $self->fetch_by_dbIDs($id);
   my @v = values %$sfh;
   return pop @v;
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

   my @sfids;
   while( my $arrayref = $sth->fetchrow_arrayref )  {
       my ($sf_id) = @{$arrayref};
       push(@sfids,$sf_id);
   }
   my $sfh = $self->fetch_by_dbIDs(\@sfids);
   return values %$sfh;
}


=head2 store

 Title   : store
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut


sub _nextid {
	my ($self) = @_;
	unless ($self->{_nextFeatureid}){$self->{_nextFeatureid} = 0}
	return ++$self->{_nextFeatureid};
}

sub store{
   my ($self,$feature,$rank,$bioentryid) = @_;

   if( !defined $bioentryid ) {
       $self->throw("Must store a seqfeature with a rank and bioentry id");
   }

   my $keyid = $self->db->get_OntologyTermAdaptor->get_id($feature->primary_tag);
   my $sourceid = $self->db->get_SeqFeatureSourceAdaptor->store_if_needed($feature->source_tag);

   
   my $sth = $self->prepare("insert into seqfeature (bioentry_id,seqfeature_key_id,seqfeature_source_id,seqfeature_rank) VALUES ($bioentryid,$keyid,$sourceid,$rank)");
   
   $sth->execute();
   my $last_id = $self->get_last_id;

   eval {
       $self->db->get_SeqLocationAdaptor->store($feature->location,$last_id);
   };
   if ($@) {
       use Data::Dumper;
       print Dumper $feature;
       $self->throw($@);
   }

      my $adp = $self->db->get_OntologyTermAdaptor();

      foreach my $tag ( $feature->all_tags() ) {
         my $qid = $adp->get_id($tag);

         # cjm: store dbxrefs for seqfeatures too
         # redundant with seqfeature_qualifier_value
         if ($tag eq "db_xref") {
             foreach my $value ( $feature->each_tag_value($tag) ) {
                 my $dbxref = Bio::Annotation::DBLink->new();
                 $value =~ /(\w+):(.*)/;
                 if ($2) {
                     $dbxref->database($1);
                     $dbxref->primary_id($2);
                 }
                 else {
                     $dbxref->database("");
                     $dbxref->primary_id($value);
                 }
                 my $xid = $self->db->get_DBXrefAdaptor()->store($dbxref);
                 $self->insert_nopk("seqfeature_dbxref",
                                    {dbxref_id=>$xid,
                                     seqfeature_id=>$last_id});
             }
         }

          # placeholder would be more efficient here
         my $rank = 1;
         foreach my $value ( $feature->each_tag_value($tag) ) {
             $value = $self->quote($value);
            my $sth= $self->prepare("INSERT into seqfeature_qualifier_value (seqfeature_id,ontology_term_id,qualifier_value,qualifier_rank) VALUES ($last_id,$qid,$value,$rank)");
            $sth->execute;
            $rank++;
         }
      }
}

sub _storeText {
   my ($self, $feature, $rank, $bioentryid, $keyid, $sourceid)=@_;
   my $last_id = $self->_nextid;
   my $fh = $self->db->{"__seqfeature"};
   print $fh "$last_id\t$bioentryid\t$keyid\t$sourceid\t$rank\n";
   
   $self->db->get_SeqLocationAdaptor->store($feature->location,$last_id);

   my $adp = $self->db->get_SeqFeatureQualifierAdaptor();

   foreach my $tag ( $feature->all_tags() ) {
      my $qid = $adp->store_if_needed($tag);

       # placeholder would be more efficient here
      my $rank = 1;
      foreach my $value ( $feature->each_tag_value($tag) ) {
         $value = $self->quote($value);
         my $fh = $self->db->{"__seqfeature_qualifier_value"};
         print $fh "$last_id\t$qid\t$rank\t$value\n";
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
        return unless $sf;
	
	my $sth;
	
	$self->db->get_SeqLocationAdaptor->remove_by_dbID(@_); 
	
 	$self->db->get_SeqFeatureSourceAdaptor->_clean_orphans; 
# 	$self->db->get_SeqFeatureKeyAdaptor->_clean_orphans; 
 
	
	$sth = $self->prepare("DELETE FROM seqfeature_qualifier_value WHERE seqfeature_id IN($sf)");
	$sth->execute();

	$sth = $self->prepare("DELETE FROM seqfeature_dbxref WHERE seqfeature_id IN ($sf)");
	$sth->execute();

	$sth = $self->prepare("DELETE FROM seqfeature WHERE seqfeature_id IN($sf)");
	$sth->execute();
	$sth->finish;	
	
	return ++$#_; 	
}
