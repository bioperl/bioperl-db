# $Id$

# POD documentation - main docs before the code

=head1 NAME

Bio::DB::SQL::DBAdapter - Object representing an instance of a bioperl database

=head1 SYNOPSIS

    $db = Bio::DB::SQL::DBAdaptor->new(
        -user   => 'root',
        -dbname => 'pog',
        -host   => 'caldy',
        -driver => 'mysql',
	    );


=head1 DESCRIPTION

This object represents a database that is implemented somehow (you
shouldn\'t care much as long as you can get the object). From the
object you can pull out other adapters, such as the BioSeqAdapter,


=head1 CONTACT

Describe contact details here

=head1 APPENDIX

The rest of the documentation details each of the object methods. Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::DB::SQL::DBAdaptor;

use vars qw(@ISA);
use strict;

use Bio::Root::Root;
use Bio::DB::SQL::SeqAdaptor;
use Bio::DB::SQL::PrimarySeqAdaptor;
use Bio::DB::SQL::BioDatabaseAdaptor;
use Bio::DB::SQL::SeqFeatureKeyAdaptor;
use Bio::DB::SQL::OntologyTermAdaptor;
use Bio::DB::SQL::SeqFeatureSourceAdaptor;
use Bio::DB::SQL::SeqLocationAdaptor;
use Bio::DB::SQL::SeqFeatureAdaptor;
use Bio::DB::SQL::CommentAdaptor;
use Bio::DB::SQL::DBLinkAdaptor;
use Bio::DB::SQL::DBXrefAdaptor;
use Bio::DB::SQL::SpeciesAdaptor;
use Bio::DB::SQL::ReferenceAdaptor;

use DBI;
use FileHandle;

@ISA = qw(Bio::Root::Root);

sub new {
  my($pkg, @args) = @_;

  my $self = $pkg->SUPER::new(@args);
  #bless {}, $pkg;

    my (
        $db,
        $host,
        $driver,
        $user,
        $password,
        $port,
        $dbh,
	    ) = $self->_rearrange([qw(
            DBNAME
	    HOST
	    DRIVER
	    USER
	    PASS
	    PORT
	    DBH
	    )],@args);
  if ($dbh) {
      $self->_db_handle($dbh);
      return $self;
  }
    $db   || $self->throw("Database object must have a database name");
    $user || $self->throw("Database object must have a user");
    if( ! $driver ) {
        $driver = 'mysql';
    }
    if( ! $host ) {
        $host = 'localhost';
    }
    if ( ! $port ) {
        $port = '';
    }
    

  my $dsn;
  if( $driver eq 'mysql' ) { 
      $dsn = "DBI:$driver:database=$db;host=$host;port=$port";
  }
  elsif( $driver eq 'Pg' ) {
      $dsn = "DBI:$driver:dbname=$db;host=$host";
      $dsn .= ";port=$port" if $port;
  }
  else {
      $self->throw("unknown driver:$driver\n");
  }
  eval {
      $dbh = DBI->connect("$dsn","$user",$password, {RaiseError => 1});
  };
  if ($@) {
      $self->throw("connection err:$@");
  }
  $dbh->{ChopBlanks} = 1;
  $dbh || $self->throw("Could not connect to database $db user $user using [$dsn] as a locator Die is $@, DBI error".$DBI::errstr);
  
  $self->_db_handle($dbh);
  $self->username( $user );
  $self->driver( $driver );
  $self->host( $host );
  $self->dbname( $db );
 
  
  return $self; # success - we hope!
}

#Simple getsets for the dbhandle parameters, in case they need to be called

sub dbname {
  my ($self, $arg ) = @_;
  ( defined $arg ) &&
    ( $self->{_dbname} = $arg );
  $self->{_dbname};
}

sub driver {
  my ($self, $arg ) = @_;
  ( defined $arg ) &&
    ( $self->{_driver} = $arg );
  $self->{_driver};
}

sub username {
  my ($self, $arg ) = @_;
  ( defined $arg ) &&
    ( $self->{_username} = $arg );
  $self->{_username};
}

sub host {
  my ($self, $arg ) = @_;
  ( defined $arg ) &&
    ( $self->{_host} = $arg );
  $self->{_host};
}

=head2 prepare

 Title   : prepare
 Usage   : $sth = $dbobj->prepare("select seq_start,seq_end from feature where analysis = \" \" ");
 Function: prepares a SQL statement on the DBI handle
 Example :
 Returns : A DBI statement handle object
 Args    : a SQL string


=cut

sub prepare {
   my ($self,$string) = @_;

   if( ! $string ) {
       $self->throw("Attempting to prepare an empty SQL query!");
   }
   if( !defined $self->_db_handle ) {
      $self->throw("Database object has lost its database handle! getting otta here!");
   }
   return $self->_db_handle->prepare($string);
}


=head2 get_PrimarySeqAdaptor

 Title   : get_PrimarySeqAdaptor
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub get_PrimarySeqAdaptor{
   my ($self) = @_;

   if( !defined $self->{'_primaryseqadaptor'} ) {
       $self->{'_primaryseqadaptor'} = Bio::DB::SQL::PrimarySeqAdaptor->new($self);
   }

   return $self->{'_primaryseqadaptor'}
}

=head2 get_SeqAdaptor

 Title   : get_SeqAdaptor
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub get_SeqAdaptor{
   my ($self,@args) = @_;

   if( !defined $self->{'_seqadaptor'} ) {
       $self->{'_seqadaptor'} = Bio::DB::SQL::SeqAdaptor->new($self);
   }

   return $self->{'_seqadaptor'}
}

=head2 get_BioDatabaseAdaptor

 Title   : get_BioDatabaseAdaptor
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub get_BioDatabaseAdaptor{
   my ($self) = @_;



   if( !defined $self->{'_biodbadaptor'} ) {
       $self->{'_biodbadaptor'} = Bio::DB::SQL::BioDatabaseAdaptor->new($self);
   }

   return $self->{'_biodbadaptor'}

}

=head2 get_SeqFeatureKeyAdaptor

 Title   : get_SeqFeatureKeyAdaptor
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub get_SeqFeatureKeyAdaptor{
   my ($self) = @_;

   if( !defined $self->{'_seqkeydbadaptor'} ) {
       $self->{'_seqkeydbadaptor'} = Bio::DB::SQL::SeqFeatureKeyAdaptor->new($self);
   }

   return $self->{'_seqkeydbadaptor'}

}


=head2 get_OntologyTermAdaptor

 Title   : get_OntologyTermAdaptor
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub get_OntologyTermAdaptor{
   my ($self) = @_;

   if( !defined $self->{'_ontology_term_adaptor'} ) {
       $self->{'_ontology_term_adaptor'} = Bio::DB::SQL::OntologyTermAdaptor->new($self);
   }

   return $self->{'_ontology_term_adaptor'}
}

=head2 get_SeqFeatureSourceAdaptor

 Title   : get_SeqFeatureSourceAdaptor
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub get_SeqFeatureSourceAdaptor{
   my ($self) = @_;

   if( !defined $self->{'_seq_source_adaptor'} ) {
       $self->{'_seq_source_adaptor'} = Bio::DB::SQL::SeqFeatureSourceAdaptor->new($self);
   }

   return $self->{'_seq_source_adaptor'}

}


=head2 get_SeqLocationAdaptor

 Title   : get_SeqLocationAdaptor
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub get_SeqLocationAdaptor{
   my ($self) = @_;

   if( !defined $self->{'_seq_location_adaptor'} ) {
       $self->{'_seq_location_adaptor'} = Bio::DB::SQL::SeqLocationAdaptor->new($self);
   }

   return $self->{'_seq_location_adaptor'}

}



=head2 get_SeqLocationAdaptor

 Title   : get_SeqLocationAdaptor
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub get_SeqFeatureAdaptor{
   my ($self) = @_;

   if( !defined $self->{'_seq_feature_adaptor'} ) {
       $self->{'_seq_feature_adaptor'} = Bio::DB::SQL::SeqFeatureAdaptor->new($self);
   }

   return $self->{'_seq_feature_adaptor'}

}


=head2 get_CommentAdaptor

 Title   : get_CommentAdaptor
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub get_CommentAdaptor{
   my ($self) = @_;

   if( !defined $self->{'_comment_adaptor'} ) {
       $self->{'_comment_adaptor'} = Bio::DB::SQL::CommentAdaptor->new($self);
   }

   return $self->{'_comment_adaptor'}

}

=head2 get_ReferenceAdaptor

 Title   : get_ReferenceAdaptor
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub get_ReferenceAdaptor{
   my ($self) = @_;

   if( !defined $self->{'_reference_adaptor'} ) {
       $self->{'_reference_adaptor'} = Bio::DB::SQL::ReferenceAdaptor->new($self);
   }

   return $self->{'_reference_adaptor'}

}


=head2 get_DBLinkAdaptor

 Title   : get_DBLinkAdaptor
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub get_DBLinkAdaptor{
   my ($self) = @_;

   if( !defined $self->{'_dblink_adaptor'} ) {
       $self->{'_dblink_adaptor'} = Bio::DB::SQL::DBLinkAdaptor->new($self);
   }

   return $self->{'_dblink_adaptor'}

}

=head2 get_DBXrefAdaptor

 Title   : get_DBXrefAdaptor
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub get_DBXrefAdaptor{
   my ($self) = @_;

   if( !defined $self->{'_dbxref_adaptor'} ) {
       $self->{'_dbxref_adaptor'} = Bio::DB::SQL::DBXrefAdaptor->new($self);
   }

   return $self->{'_dbxref_adaptor'}

}


=head2 get_SpeciesAdaptor

 Title   : get_SpeciesAdaptor
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub get_SpeciesAdaptor{
   my ($self) = @_;

   if( !defined $self->{'_species_adaptor'} ) {
       $self->{'_species_adaptor'} = Bio::DB::SQL::SpeciesAdaptor->new($self);
   }

   return $self->{'_species_adaptor'}

}


=head2 get_dbNames

 Title   : get_dbNames
 Usage   : $obj->get_dbNames()
 Function: find all possible biodatabase.name's available
 Example : 
 Returns : list of biodatabase.name fields
 Args    : none


=cut

sub get_dbNames{
   my ($self) = @_;
   my $dbh =  $self->{'_db_handle'};
   return undef unless $dbh;

	my $sth = $dbh->prepare('select name from biodatabase');
	$sth->execute;
	my @namelist;
	while (my ($dbn) = $sth->fetchrow_array){
		push @namelist, $dbn;
	}
    return @namelist;

}

=head2 _db_handle

 Title   : _db_handle
 Usage   : $obj->_db_handle($newval)
 Function: 
 Example : 
 Returns : value of _db_handle
 Args    : newvalue (optional)


=cut

sub _db_handle{
   my ($self,$value) = @_;
   if( defined $value) {
      $self->{'_db_handle'} = $value;
    }
    return $self->{'_db_handle'};

}

sub begin_work { shift->_db_handle->begin_work }
sub commit { shift->_db_handle->commit }
sub rollback { shift->_db_handle->rollback }
sub disconnect { shift->_db_handle->disconnect }

=head2 DESTROY

 Title   : DESTROY
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub DESTROY {
   my ($obj) = @_;
   #$obj->_unlock_tables();

   if( $obj->{'_db_handle'} ) {
       $obj->{'_db_handle'}->disconnect;
       $obj->{'_db_handle'} = undef;
   }
   $obj->SUPER::DESTROY();
}


1;
