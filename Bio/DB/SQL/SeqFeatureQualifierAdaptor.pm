
#
# BioPerl module for Bio::DB::SQL::SeqFeatureKeyAdaptor.pm
#
# Cared for by Ewan Birney <birney@ebi.ac.uk>
#
# Copyright Ewan Birney
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::DB::SQL::SeqFeatureKeyAdaptor.pm - DESCRIPTION of Object

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


package Bio::DB::SQL::SeqFeatureQualifierAdaptor;
use vars qw(@ISA);
use strict;

# Object preamble - inherits from Bio::Root::RootI

use Bio::DB::SQL::BaseAdaptor;


@ISA = qw(Bio::DB::SQL::BaseAdaptor);

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
   
   $self->{'_name_dbID'} = {};
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
   my ($self,$name) = @_;

   # in local cache?
   if( exists $self->{'_name_dbID'}->{$name} ) {
       return $self->{'_name_dbID'}->{$name};
   }

   # could be in database 
   my $sth = $self->prepare("select seqfeature_qualifier_id from seqfeature_qualifier where qualifier_name = '$name'");
   $sth->execute;
   my ($dbid) = $sth->fetchrow_array();
   if( defined $dbid ) {
       $self->{'_name_dbID'}->{$name} = $dbid;
       return $dbid;
   }
   
   # nope - insert
   $sth = $self->prepare("insert into seqfeature_qualifier (seqfeature_qualifier_id,qualifier_name) VALUES (NULL,'$name')");
   $sth->execute;
   $sth = $self->prepare("select LAST_INSERT_ID()");
   $sth->execute;

   $dbid = $sth->fetchrow_array();
   if( defined $dbid ) {
       $self->{'_name_dbID'}->{$name} = $dbid;
       return $dbid;
   } else {
       $self->throw("Very weird - we got a successful insert but no valid db id. Truly bizarre");
   }
}

1;
