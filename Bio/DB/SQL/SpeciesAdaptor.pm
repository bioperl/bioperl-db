
#
# BioPerl module for Bio::DB::SQL::SpeciesAdaptor
#
# Cared for by Ewan Birney <birney@ebi.ac.uk>
#
# Copyright Ewan Birney
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::DB::SQL::SpeciesAdaptor - DESCRIPTION of Object

=head1 SYNOPSIS

Give standard usage here

=head1 DESCRIPTION

Species DB adaptor 

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


package Bio::DB::SQL::SpeciesAdaptor;
use vars qw(@ISA);
use strict;

# Object preamble - inherits from Bio::Root::RootI

use Bio::DB::SQL::BaseAdaptor;
use Bio::Species;


@ISA = qw(Bio::DB::SQL::BaseAdaptor);
# new() can be inherited from Bio::Root::RootI

=head2 new

 Title   : new
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub new{
   my ($class,@args) = @_;

   my $self = Bio::DB::SQL::BaseAdaptor->new(@args);
   bless $self,$class;
   
   $self->{'_linneage_hash'} = {};
   $self->{'_id_to_object'} = {};


   return $self;
}


=head2 store_if_needed

 Title   : store_if_needed
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub store_if_needed{
   my ($self,$species) = @_;

   my $str = join(':',$species->classification());
   if( exists $self->{'_linneage_hash'}->{$str} ) {
       return $self->{'_linneage_hash'}->{$str};
   }
   $str =~ s/\'/\\\'/g;
   my $sth = $self->prepare("select taxa_id from taxa where full_lineage = '$str'");
   $sth->execute();

   my ($taxa) = $sth->fetchrow_array();
   
   if( defined $taxa ) {
       $self->{'_linneage_hash'}->{$str} = $taxa;
       return $taxa;
   }

   # write it into the database

   my $common_name  = $species->common_name;
   if( !defined $common_name ) {
       $common_name = "";
   }
   $common_name =~ s/\'/\\\'/g; 
   $sth = $self->prepare("insert into taxa (taxa_id,full_lineage,common_name) values (NULL,'$str','$common_name')");
   $sth->execute;

   $sth = $self->prepare("select last_insert_id()");
   $sth->execute();
   my ($id) = $sth->fetchrow_array;

   $self->{'_linneage_hash'}->{$str} = $id;

   return $id;
}


=head2 fetch_by_dbID

 Title   : fetch_by_dbID
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub fetch_by_dbID {
   my ($self,$dbid) = @_;

   if( exists $self->{'_id_to_object'}->{$dbid} ) {
       return $self->{'_id_to_object'}->{$dbid};
   }

   my $sth = $self->prepare("select full_lineage,common_name from taxa where taxa_id = $dbid");
   $sth->execute;
   my ($full_lineage,$common_name) = $sth->fetchrow_array();

   my @classification = split(/:/,$full_lineage);
 
   my $out = Bio::Species->new(-classification => \@classification);
   $out->common_name($common_name);
   $self->{'_id_to_object'}->{$dbid} = $out;

   return $out;
   
}

