
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
use vars qw($@ISA);
use strict;

# Object preamble - inherits from Bio::Root::RootI

use Bio::DB::SQL::BaseAdaptor;


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

   my $sth = $self->prepare("select k.key_name,s.source_name from seqfeature sf,seqfeature_key k,seqfeature_source s,f.seqfeature_key_id = k.seqfeature_key_id and and f.seqfeature_source_id = s.seqfeature_source_id and f.seqfeature_id = $id");
   $sth->execute();

   my ($key,$source) = $sth->fetchrow_array();

   $generic->primary_tag($key);
   $generic->source($source);

   # get out the location
   # we are not dealing with remote locations here.

   $sth = $self->prepare("select seq_start,seq_end,seq_strand from seqfeature_location where seqfeature_id = $id order by reverse location_rank");
   $sth->execute();
   
   

   my $loc = Bio::SeqFeature::Location->new();
   

}


