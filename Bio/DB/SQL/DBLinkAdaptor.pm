
#
# BioPerl module for Bio::DB::SQL::DBLinkAdaptor
#
# Cared for by Ewan Birney <birney@ebi.ac.uk>
#
# Copyright Ewan Birney
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::DB::SQL::DBLinkAdaptor - DESCRIPTION of Object

=head1 SYNOPSIS

Give standard usage here

=head1 DESCRIPTION

Adaptor for DBLinks 

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


package Bio::DB::SQL::DBLinkAdaptor;
use vars qw(@ISA);
use strict;
use Bio::Annotation::DBLink;

# Object preamble - inherits from Bio::Root::RootI

use Bio::DB::SQL::BaseAdaptor;


@ISA = qw(Bio::DB::SQL::BaseAdaptor);
# new() can be inherited from Bio::Root::RootI


=head2 fetch_by_dbID

 Title   : fetch_by_dbID
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub fetch_by_dbID{
   my ($self,$dbid) = @_;

   my $sth = $self->prepare("select dbname,accession from bioentry_direct_links where bio_dblink_id = $dbid");
   $sth->execute;

   my ($dbname,$acc) = $sth->fetchrow_array();

   my $dblink = Bio::Annotation::DBLink->new();

   $dblink->database($dbname);
   $dblink->primary_id($acc);

   return $dblink;
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
   my $sth = $self->prepare("select bio_dblink_id from bioentry_direct_links where source_bioentry_id = $bioentry_id");
   $sth->execute;

   my @out;
   while( my $arrayref = $sth->fetchrow_arrayref )  {
       my ($biodblink_id) = @{$arrayref};
       push(@out,$self->fetch_by_dbID($biodblink_id));
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
   my ($self,$dblink,$bioentry_id) = @_;

   if( !defined $bioentry_id ) {
       $self->throw("must store dblinks with bioentries");
   }

   my $acc = $dblink->primary_id();
   my $db  = $dblink->database();

   my $sth = $self->prepare("insert into bioentry_direct_links (bio_dblink_id,source_bioentry_id,dbname,accession) VALUES (NULL,$bioentry_id,'$db','$acc')");

   $sth->execute;

   return;
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
	my($self) = shift; 
	
	my ($be) = join (",",@_);
	
	my $sth = $self->prepare("DELETE FROM bioentry_direct_links WHERE source_bioentry_id IN ($be)"); 
	$sth->execute(); 
}
