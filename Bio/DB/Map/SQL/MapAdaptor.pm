
#
# BioPerl module for Bio::DB::Map::SQL::MapAdaptor
#
# Cared for by Jason Stajich <jason@chg.mc.duke.edu>
#
# Copyright Jason Stajich
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::DB::Map::SQL::MapAdaptor - DESCRIPTION of Object

=head1 SYNOPSIS

Give standard usage here

=head1 DESCRIPTION

Describe the object here

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

Describe contact details here

=head1 APPENDIX

The rest of the documentation details each of the object
methods. Internal methods are usually preceded with a _

=cut

# Let the code begin...

package Bio::DB::Map::SQL::MapAdaptor;
use vars qw(@ISA);
use strict;

use Bio::DB::SQL::BaseAdaptor;
use Bio::DB::Map::Map;

@ISA = qw(Bio::DB::SQL::BaseAdaptor);


=head2 get

 Title   : get
 Usage   : my $map = $adaptor->get(-id => $mapid); OR
           my $map = $adaptor->get(-name => $name); 
 Function: finds the map based on a criteria
 Returns : Bio::DB::Map::MapI object
 Args    : -id => mapid OR
           -name => mapname

=cut

sub get{
   my ($self,@args) = @_;
   my ($id,$name) = $self->_rearrange([qw(ID NAME)], @args);

   if( $id && $name ) {
       $self->warn("Requesting map by both id and name, will only use id");
   }
   if( ! $id && ! $name ) {
       $self->warn("Requested map without id or name, cannot proceed");
       return undef;
   }
   my $map;
   eval {
       my $SQL = q(SELECT 
		   mapid as '-id',
		   name  as '-name',
		   units as '-units'
		   FROM map WHERE );
       if( $id ) {
	   $SQL .= 'mapid = ?';
       } else { 
	   $SQL .= 'name = ?';
       }
       my $sth = $self->prepare($SQL); 
       if( ! $id  ) { $id = $name; }
       $sth->execute($id );
       my $row;
       # only want the first hit, plus name and mapid are both unique fields
       if( defined($row = $sth->fetchrow_hashref ) ){ 
	   $map = new Bio::DB::Map::Map( '-adaptor' => $self,
					 %{$row} );
       } else { 
	   $self->warn("Searching for $id did not find any maps");
       }
       $sth->finish();
   };
   if($@ ) {
       $self->warn($@);
   }
   return $map;
}


=head2 write

 Title   : write
 Usage   : $mapadaptor->write($map);
 Function: adds a new map to the database
 Returns : Bio::DB::Map::MapI object
 Args    : Bio::DB::Map::MapI object

=cut

sub write{
   my ($self,$map) = @_;

   eval { 
       my $sth = $self->prepare(q(INSERT INTO map ( name, units) 
				  VALUES ( ?, ? ) ));
       $sth->execute($map->name,$map->units);
       $map->id($sth->{'mysql_insertid'});
   };
   if( $@ ){
       $self->warn($@);
       $map = undef;
   }
   $map->adaptor($self);
   return $map;
}


=head2 get_mapids_hash

 Title   : get_mapids_hash
 Usage   : my %mapnames = $adaptor->get_mapids_hash();
 Function: returns a hash of mapnames => mapids and mapids => mapnames
 Returns : hash which 
 Args    : none


=cut

sub get_mapids_hash {
   my ($self) = @_;
   
   my %mapinfo;
   eval {
       my $sth = $self->prepare("SELECT mapid, name FROM map");
       $sth->execute();
       
       while( my($mapid,$name) = $sth->fetchrow_array ) {
	   $mapinfo{$mapid} = $name;
	   $mapinfo{$name} = $mapid;	   
       }
       $sth->finish();
   };
   if( $@ ){
       $self->warn($@);       
   }
   return %mapinfo;
}

=head2 get_markers_for_region

 Title   : get_markers_for_region
 Usage   : my @markers = $map->get_markers_for_region('-start' => $start,
						      '-end'   => $end);
 Function: returns a list of markers for this map that fall between
           start and end in this map\'s units.  Omitting 'start' will
           default to the beginning of the map, omitting 'end' will
           default to the end of map.
 Returns : List of Bio::DB::Map::MarkerI objects
 Args    : -start => starting point or region (in units of this map)
           -end   => ending point of region (in units of this map)
           -chrom => chromosome [1,22,X,Y]
           -id    => map id
=cut

sub get_markers_for_region{
   my ($self,@args) = @_;
   
   my ( $start, $end,$chrom,$id ) = $self->_rearrange([qw(START END 
							  CHROM ID)], 
						      @args);

   $start = 0 unless defined $start;
   if( !defined $end ) {
       $end = $self->map_length();
   }
   
   my $SQL =q(SELECT p.markerid from marker m, map_position p 
	      WHERE m.chrom = ? AND m.mapid = ?
	      AND m.mapid = p.mapid AND
	      p.position >= ? AND p.position <= ?
	      );
		
   my $marker_adaptor = new Bio::DB::Map::SQL::MarkerAdaptor($self);
   my @m;   
   eval { 
       my $sth = $self->prepare($SQL);
       $sth->execute($chrom,$id,$start,$end);       
       while( my ($markerid) = $sth->fetchrow_array) {
	   push @m, $markerid;
       }
   };
   if( $@ ) {  $self->throw($@); }
   my @markers = $marker_adaptor->get_Markers('-ids' => \@m);   
   return @markers;
}

=head2 get_next_marker

 Title   : get_next_marker
 Usage   : my $marker = $map->get_next_marker(-marker => $marker,
					      -direction => 1);
 Function: returns the next marker in the map based on the given marker
           and either a positive or negative direction
 Returns : Bio::DB::Map::MarkerI object or undef 
 Args    : -marker => $marker Bio::DB::Map::MarkerI object to start with
           -direction => [1,-1]
=cut

sub get_next_marker{
   my ($self,@args) = @_;
   my ($marker,$direction) = $self->_rearrange([qw(MARKER DIRECTION)],
					       @args);
   if( !defined $marker ) {
       $self->warn("Did not specify a marker to anchor the search");
       return undef;
   }
   $direction = 1 unless defined $direction;

}

=head2 get_Chrom_length

 Title   : get_Chrom_length
 Usage   : my $len = $map->get_Chrom_Length()
 Function: Returns the length of a chromosome for a Map in the map\'s units
 Returns : float
 Args    : map id, chromsome

=cut

sub get_Chrom_length{
   my ($self,$id,$chrom) = @_;
   
   my $SQL = q(SELECT max(position) 
	       FROM map_position p, marker m
	       WHERE m.chrom = ? AND p.mapid = ? AND 
	       m.markerid = p.markerid);
   my ($len);
   eval { 
       my $sth = $self->prepare($SQL);
       $sth->execute($chrom,$id);
       ($len) = $sth->fetchrow_array;
       $sth->finish();
   };
   if( $@ ) {
       $self->throw($@);
   }
   return $len || '0';
}

1;
