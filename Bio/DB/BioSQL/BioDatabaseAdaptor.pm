
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

Bio::DB::SQL::BioDatabaseAdaptor - Adaptor for BioDatabase table

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
use Bio::DB::BioSeqDatabase;

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

   my $id;
   eval {
       $id = $self->fetch_by_name($name);
   };

   #if( !defined $id || $id eq '' ) {
   if ($@) {
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
	
   if (! defined $id) {
	$self->throw("Could not find db for name $name");
   }	

   return $id;
}



=head2 fetch_BioSeqDatabase_by_name

 Title   : fetch_BioSeqDatabase_by_name
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub fetch_BioSeqDatabase_by_name{
   my ($self,$name) = @_;
   
   my $id = $self->fetch_by_name($name);
   my $db = Bio::DB::BioSeqDatabase->new( -adaptor => $self,
					  -dbid    => $id);

   $db->name($name);

   return $db;
}


=head2 fetch_Seq_by_display_id

 Title   : fetch_Seq_by_display_id
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub fetch_Seq_by_display_id{
   my ($self,$dbid,$id) = @_;

   my $sth = $self->prepare("select bioentry_id from bioentry where biodatabase_id = $dbid and display_name = '$id'");
   $sth->execute;
   my ($bid) = $sth->fetchrow_array();

   if( !defined $bid ) {
       $self->throw("Unable to find sequence in $dbid database for $id");
   }
   return $self->db->get_SeqAdaptor->fetch_by_dbID($dbid);
}

=head2 fetch_Seq_by_display_id

 Title   : fetch_Seq_by_display_id
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub fetch_Seq_by_accession{
   my ($self,$dbid,$acc) = @_;

   #print STDERR "Asking for accession $acc with select bioentry_id from bioentry where biodatabase_id = $dbid and accession = '$acc'\n";
   my $sth = $self->prepare("select bioentry_id from bioentry where biodatabase_id = $dbid and accession = '$acc'");
   $sth->execute;
   my $ref = $sth->fetchrow_arrayref();
   my $bid = $ref->[0];
   
   if( !defined $bid ) {
       $self->throw("Unable to find sequence in $dbid database for $acc");
   }
   return $self->db->get_SeqAdaptor->fetch_by_dbID($bid);
}

=head2 list_biodatabase_ids

 Title   : list_biodatabase_ids
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub list_biodatabase_names{

   my ($self) = @_;

   my $sth = $self->prepare("select name from biodatabase");
   $sth->execute;
   
   my @out;
   while( (my $ref = $sth->fetchrow_arrayref()) ) {
       push(@out,@{$ref});
   }
	  
   return @out;

}



=head2 list_bioentry_ids

 Title   : list_bioentry_ids
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub list_bioentry_ids{
   my ($self,$dbid) = @_;

   my $sth = $self->prepare("select accession from bioentry where biodatabase_id = $dbid");
   $sth->execute;
   
   my @out;
   while( (my $ref = $sth->fetchrow_arrayref()) ) {
       push(@out,@{$ref});
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
   my ($self,$name) = @_;

   my $sth = $self->prepare("insert into biodatabase (biodatabase_id,name) values (NULL,'$name')");
   $sth->execute;
   $sth = $self->prepare("select LAST_INSERT_ID()");
   $sth->execute;
   my ($id) = $sth->fetchrow_array;

   return $id;
}


=head2 remove

 Title   : remove
 Usage   : remove(database_name)
 Function: Deletes biodatabase from SQL database. 
 Example : 
 Returns : 
 Args    : name of the database to be deleted

=cut



sub remove_by_name{
   my ($self,$name) = @_;
   $self->throw("No database name specified") unless ($name);  	
   
   my $dbid = $self->fetch_by_name($name); 
   
   if( !defined $dbid ) {
       $self->throw("Unable to find database $name");
   }
   
   	my $sth = $self->prepare("DELETE FROM biodatabase WHERE biodatabase_id=$dbid"); 
	$sth->execute; 

# Finding bioentries that belong to the database 

	$sth = $self->prepare("SELECT bioentry_id FROM bioentry WHERE biodatabase_id=$dbid");
	$sth->execute();
	my $be = $sth->fetchrow_array(); 
	while (my $a = $sth->fetchrow_array) {
		$be = $be.",".$a; 
	}
	
	return unless $be; 
	
#	$self->db->get_SeqAdaptor->remove_by_dbID(@be);  

	   
}

