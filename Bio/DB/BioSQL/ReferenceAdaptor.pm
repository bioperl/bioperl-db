
#
# BioPerl module for Bio::DB::SQL::ReferenceAdaptor
#
# Cared for by Elia Stupka <elia@ebi.ac.uk>
#
# Copyright Elia Stupka
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::DB::SQL::ReferenceAdaptor - DESCRIPTION of Object

=head1 SYNOPSIS

Give standard usage here

=head1 DESCRIPTION

Adaptor for Reference objects inside bioperl db 

=head1 FEEDBACK

=head2 Mailing Lists

User feedback is an integral part of the evolution of this
and other Bioperl modules. Send your references and suggestions preferably
 to one of the Bioperl mailing lists.
Your participation is much appreciated.

  bioperl-l@bio.perl.org

=head2 Reporting Bugs

Report bugs to the Bioperl bug tracking system to help us keep track
 the bugs and their resolution.
 Bug reports can be submitted via email or the web:

  bioperl-bugs@bio.perl.org
  http://bio.perl.org/bioperl-bugs/

=head1 AUTHOR - Elia Stupka

Email elia@ebi.ac.uk


=head1 APPENDIX

The rest of the documentation details each of the object methods. Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::DB::SQL::ReferenceAdaptor;
use vars qw(@ISA);
use strict;
use Bio::Annotation::Reference;

use Bio::DB::SQL::BaseAdaptor;

@ISA = qw(Bio::DB::SQL::BaseAdaptor);

=head2 fetch_by_dbID

 Title   : fetch_by_dbID
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub fetch_by_dbID {
   my ($self,$referenceid) = @_;

   my $sth = $self->prepare("select reference_authors,reference_title,reference_location,reference_medline from reference where reference_id = $referenceid");

   $sth->execute;
   my ($authors,$title,$loc,$med) = $sth->fetchrow_array();

   my $ref = Bio::Annotation::Reference->new(
					     -title => $title,
					     -authors => $authors,
					     -location => $loc,
					     -medline => $med
					     );


   return $ref;
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
   my $sth = $self->prepare("select reference_id,reference_start,reference_end from bioentry_reference where bioentry_id = $bioentry_id order by reference_rank");
   $sth->execute;

   my @out;
   while( my $arrayref = $sth->fetchrow_arrayref )  {
       my ($biodblink_id,$start,$end) = @{$arrayref};
       my $ref=$self->fetch_by_dbID($biodblink_id);
       $ref->start($start);
       $ref->end($end);
       push(@out,$ref);
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

sub store_if_needed{
   my ($self,$reference) = @_;

   $reference || $self->throw("Need a reference to store, doh...");

   my $authors=$reference->authors;
   my $location=$reference->location;
   my $title=$reference->title;
   $title =~ s/\'/\\\'/g;
   $authors =~ s/\'/\\\'/g;
   $location =~ s/\'/\\\'/g;
   #Hack, put zero for records that have no medline id
   #This allows us to define the medline field as NOT NULL
   #and therefore can be indexed, which speeds up the check below
   my $med='0';
   if ($reference->medline) {
       $med=$reference->medline;
   }

   if ($med) {
       my $sth= $self->prepare("select reference_id from reference where reference_medline = $med");
       $sth->execute();
       my ($id) = $sth->fetchrow_array();
       if ($id) {
	   return $id;
       }
   }

   my $sth = $self->prepare("insert into reference (reference_id,reference_authors,reference_title,reference_location,reference_medline) values (NULL,'$authors','$title','$location',$med)");
   #print STDERR "insert into reference (reference_id,reference_start,reference_end,reference_authors,reference_title,reference_location,reference_medline) values (NULL,$start,$end,'$authors','$title','$location',$med)\n";
   $sth->execute();
   return $sth->{'mysql_insertid'};
}


=head2 remove_by_bioentry_id

 Title   : remove_by_bioentry_id
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub remove_by_bioentry_id {
	my ($self) = shift; 
	my $be = join ",",@_; 
	
	my $sth = $self->prepare("SELECT reference_id FROM bioentry_reference WHERE bioentry_id IN($be)");
	$sth->execute(); 
	my @rf = $sth->fetchrow_array;
	
	return 0 unless @rf; 
		
	while (my $a = $sth->fetchrow_array) {
		unshift  @rf, $a; 
	}
	
	$sth = $self->prepare("DELETE FROM bioentry_reference WHERE bioentry_id IN($be)");
	$sth->execute();
	
	$self->_clean_orphans();  
	
	return $sth->rows; 
}



=head2 remove_by_dbID

 Title   : remove_by_dbID
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub remove_by_dbID {
	my($self) = shift; 
	my($rf) = join ",",@_; 
	

	my $sth = $self->prepare("DELETE FROM reference WHERE reference_id IN($rf)");
	$sth->execute; 
	
	return $sth->rows; 
}

=head2 _clean_orphans

 Title   : _clean_orphans
 Usage   : 
 Function: Checks the reference table for entries that are not linked to any reference in bioentry_reference and deletes such entries. 
 Example :
 Returns : number of references deleted
 Args    : none


=cut

sub _clean_orphans {

	my($self) = shift; 

	my $sth = $self->prepare("select reference.reference_id from reference left join bioentry_reference on ".
							"reference.reference_id = bioentry_reference.reference_id where ".
							"bioentry_reference.reference_id is NULL" )	;
	$sth->execute(); 
	
	my $orph = $sth->fetchrow_array(); 	
	return 0 if not $orph; 

	while (my $a = $sth->fetchrow_array()) {
		$orph = $orph.",".$a; 		
	}
	
	$sth = $self->prepare("DELETE FROM reference WHERE reference_id IN($orph)"); 
	$sth->execute;
		
	return $sth->rows;  
}