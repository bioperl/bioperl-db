# $Id$
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

Bio::DB::SQL::BioDatabaseAdaptor - Adaptor for BioSeqDatabases, needed \
by the Registry system, respects the ->new(\%config) interface

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

=head1 AUTHOR - Elia Stupka

Email elia@fugu-sg.org

Describe contact details here

=head1 APPENDIX

The rest of the documentation details each of the object methods. Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::DB::SQL::BioSeqDatabaseFetcher;
use vars qw(@ISA);
use strict;

use Bio::DB::BioSeqDatabase;
use Bio::DB::SQL::DBAdaptor;

@ISA = qw(Bio::Root::Root);

=head2 new

 Title   : new
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub new{
   my ($class, %conf) = @_;
   my $self = $class->SUPER::new(%conf);
   my $db = Bio::DB::SQL::DBAdaptor->new(
					 -DBNAME=>$conf{'dbname'},
	                                 -HOST=>$conf{'location'},
	                                 -DRIVER=>$conf{'driver'},
					 -USER=>$conf{'user'},
	                                 -PASS=>$conf{'pass'},
					 -PORT=>$conf{'port'}
					 );
   $self->db($db);
   my $id = $self->fetch_by_name($conf{'biodbname'});
   my $bioseqdb = Bio::DB::BioSeqDatabase->new( -adaptor => $self,
						-dbid    => $id);
   
   $bioseqdb->name($conf{'biodbname'});
   
   return $bioseqdb;
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

   my $sth = $self->db->prepare("select biodatabase_id from biodatabase where name = '$name'");
   $sth->execute;

   my ($id) = $sth->fetchrow_array();
	
   if (! defined $id) {
	$self->throw("Could not find db for name $name");
   }	

   return $id;
}

sub db {
  my ($self, $arg ) = @_;
  ( defined $arg ) &&
    ( $self->{_db} = $arg );
  $self->{_db};
}

1;
