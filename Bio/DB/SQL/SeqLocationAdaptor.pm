
#
# BioPerl module for Bio::DB::SQL::SeqLocationAdaptor
#
# Cared for by Ewan Birney <birney@ebi.ac.uk>
#
# Copyright Ewan Birney
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::DB::SQL::SeqLocationAdaptor - 

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


package Bio::DB::SQL::SeqLocationAdaptor;
use vars qw(@ISA);
use strict;

# Object preamble - inherits from Bio::Root::RootI

use Bio::DB::SQL::BaseAdaptor;

use Bio::Location::Split;
use Bio::Location::Simple;

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

   # WARNING this does not handle remote locations yet at all...


   my @array;

   my $sth = $self->prepare("select seq_start,seq_end,seq_strand from seqfeature_location where seqfeature_id = $dbid order by location_rank");
   $sth->execute();
   
   my $arrayref;
   my $count = 0;
   my $component;
   while( $arrayref = $sth->fetchrow_arrayref ) {
       my ($seq_start,$seq_end,$seq_strand) = @{$arrayref};

       $component = Bio::Location::Simple->new();
       $component->start($seq_start);
       $component->end($seq_end);
       $component->strand($seq_strand);

       push(@array,$component);
   }

   if( scalar(@array) == 0 ) {
       $self->throw("no location for $dbid");
   }

   if( scalar(@array) == 1 ) {
       return pop @array;
   }

   my $out = Bio::Location::Split->new();

   foreach my $a ( @array ) {
       $out->add_sub_Location($a);
   }

   return $out;
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
   my ($self,$location,$seqfeature_id) = @_;

   if( !defined $seqfeature_id ) {
       $self->throw("no seqfeature_id  ...");
   }

   
   if( $location->isa('Bio::Location::SplitLocationI')  ) {
       my $rank = 1;
       foreach my $sub ( $location->sub_Location ) {
	   $self->_store_component($sub,$seqfeature_id,$rank);
	   $rank++;
       }
   } elsif( $location->isa('Bio::Location::Simple') ) {
       $self->_store_component($location,$seqfeature_id,1);
   } else {
       $self->throw("Not a simple location nor a split. Yikes");
   }

       
}

=head2 _store_component

 Title   : _store_component
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub _store_component{
   my ($self,$location,$seqfeature_id,$rank) = @_;

   if( !defined $rank ) {
       $self->throw("Have to store with a rank");
   }
   my $start  = $location->start;
   my $end    = $location->end;
   my $strand = $location->strand;
 
   my $sth = $self->prepare("insert into seqfeature_location (seqfeature_location_id,seqfeature_id,seq_start,seq_end,seq_strand,location_rank) VALUES (NULL,$seqfeature_id,$start,$end,$strand,$rank)");
   $sth->execute;
   my $id= $sth->{'mysql_insertid'};

   $location->seq_id =~ /(\S+)\.(\S+)/;
   my $acc = $1;
   my $v = $2;
   if ($location->is_remote) {
       my $sth = $self->prepare("insert into remote_seqfeature_name (seqfeature_location_id,accession,version) values($id,'$acc',$v)");
       $sth->execute;
   }
   return $id;
}

1;






