
#
# BioPerl module for Bio::DB::Map::SQL::DBAdaptor
#
# Cared for by Jason Stajich <jason@chg.mc.duke.edu>
#
# Copyright Jason Stajich
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::DB::Map::SQL::DBAdaptor - Object representing an instance of a
                               bioperl Map Database

=head1 SYNOPSIS

    use Bio::DB::Map::SQL::DBAdaptor;
    my $db = new Bio::DB::Map::SQL::DBAdaptor 
    ( -user   => 'user',
      -dbname => 'markermap',
      -host   => 'localhost',
      -driver => 'mysql' );
						
=head1 DESCRIPTION

This object represents a database that is implemented somehow (you
shouldn\'t care much as long as you can get the object). From the
object you can pull out other adapters, such as MarkerAdaptor or MapAdaptor.

=head1 FEEDBACK

=head2 Mailing Lists

User feedback is an integral part of the evolution of this and other
Bioperl modules. Send your comments and suggestions preferably to the
Bioperl mailing list.  Your participation is much appreciated.

  bioperl-l@bioperl.org             - General discussion
  http://bioperl.org/MailList.shtml - About the mailing lists

=head2 Reporting Bugs

Report bugs to the Bioperl bug tracking system to help us keep track
the bugs and their resolution.  Bug reports can be submitted via email
or the web:

  bioperl-bugs@bioperl.org
  http://bioperl.org/bioperl-bugs/

=head1 AUTHOR - Jason Stajich

Email jason@chg.mc.duke.edu

=head1 APPENDIX

The rest of the documentation details each of the object
methods. Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::DB::Map::SQL::DBAdaptor;
use vars qw(@ISA);
use strict;

use Bio::Root::RootI;
use Bio::DB::Map::SQL::MapAdaptor;
use Bio::DB::Map::SQL::MarkerAdaptor;
use DBI;

@ISA = qw(Bio::Root::RootI );

=head2 new

 Title   : new
 Usage   : my $db = new Bio::DB::Map::SQL::DBAdaptor(%params);
 Function: instantiates a new DBAdaptor object
 Returns : new Bio::DB::Map::SQL::DBAdaptor object
 Args    : -user   => username
           -pass   => password to use
           -dbname => database name to use
           -host   => host where db is running
           -driver => db driver to use     
 Throws  : Exception if db connection cannot be established

=cut

sub new {
    my($class,@args) = @_;

    my $self = $class->SUPER::new(@args);
    my (
        $db,
        $host,
        $driver,
        $user,
        $password,
        $port,
        ) = $self->_rearrange([qw(
				  DBNAME
				  HOST
				  DRIVER
				  USER
				  PASS
				  )],@args);
    $db   || $self->throw("Database object must have a database name");
    $user || $self->throw("Database object must have a user");

    if( ! $driver ) {
        $driver = 'mysql';
    }
    if( ! $host ) {
        $host = 'localhost';
    }
    if ( ! $port ) {
        $port = 3306;
    }

    my $dsn = "DBI:$driver:database=$db;host=$host;port=$port";

    my $dbh = DBI->connect("$dsn","$user",$password, {RaiseError => 1});

    $dbh || $self->throw("Could not connect to database $db user $user using [$dsn] as a locator");

    $self->_db_handle($dbh);
    $self->username( $user );
    $self->host( $host );
    $self->dbname( $db );

    return $self;		# success - we hope!

}

#Simple getsets for the dbhandle parameters, in case they need to be called

sub dbname {
  my ($self, $arg ) = @_;
  ( defined $arg ) &&
    ( $self->{_dbname} = $arg );
  $self->{_dbname};
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


=head2 get_MapAdaptorAdaptor

 Title   : get_MapAdaptor
 Usage   :
 Function: get a MapAdaptor object
 Returns : Bio::DB::Map::SQL::MapAdaptor object
 Args    : none

=cut

sub get_MapAdaptor {
    my ($self) = @_;
    return new Bio::DB::Map::SQL::MapAdaptor( $self);
}


=head2 get_MarkerAdaptor

 Title   : get_MarkerAdaptor
 Usage   :
 Function: get a MarkerAdaptor object
 Returns : Bio::DB::Map::SQL::MarkerAdaptor object
 Args    : none

=cut

sub get_MarkerAdaptor {
    my ($self) = @_;
    return new Bio::DB::Map::SQL::MarkerAdaptor( $self);
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
}

1;
