
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

}

=head2 get_all_maps

 Title   : get_all_maps
 Usage   :
 Function:
 Returns : array of Bio::DB::Map::MapI objects
 Args    : none

=cut

sub get_all_maps {
    my ($self) = @_;
    my $SQL = 'SELECT mapid from map';
    my ($sth, @maps);			

    eval { 
	$sth = $self->prepare($SQL);
	$sth->execute;	
	while( my ($idval) = $sth->fetchrow_array ) {	     
	    my $map = new Bio::DB::Map::SQL::MapAdaptor( $self);
	    $map->id( $idval);	
	    push @maps, $map;
	}
	$sth->finish();
    };
    if( $@ ) {
	$self->throw($@);
    }
    return @maps;    
}

=head2 get_map

 Title   : get_map
 Usage   :
 Function:
 Returns : Bio::DB::Map::MapI object
 Args    : -id   => mapid  OR
           -name => map name

=cut

sub get_map {
    my ($self, @args) = @_;
    my ($id, $name) = $self->_rearrange([qw(ID NAME)], @args);
    
    if( $id && $name ) {
	$self->warn("Cannot request both id and name");
	return undef;
    }
    
    my $SQL ='SELECT mapid from map where ';
    if( $id ) {
	$SQL .= 'mapid = $id';
    } elsif( $name ) {
	$SQL .= sprintf('name = %s', $self->db->quote($name));
    }
    
    my ($sth, $map) = ( undef, new Bio::DB::Map::SQL::MapAdaptor( $self) );
			
    eval { 
	$sth = $self->prepare($SQL);
	$sth->execute;	
	my ($idval) = $sth->fetchrow_array;	     
	$map->id( $idval);	
	$sth->finish();
    };
    if( $@ ) {
	$self->throw($@);
    }
    return $map;
}

1;
