
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
use Bio::DB::Map::MapI;

@ISA = qw(Bio::DB::SQL::BaseAdaptor Bio::DB::Map::MapI );

sub new { 
    my ( $class, @args) = @_;
    my $self = $class->SUPER::new(@args);    
    return $self;
}

=head2 id

 Title   : id
 Usage   : $obj->id($newval)
 Function: 
 Example : 
 Returns : value of id
 Args    : newvalue (optional)

=cut

sub id{
   my ($obj,$value) = @_;
   if( defined $value) {
      $obj->{'_id'} = $value;
    }
    return $obj->{'_id'};

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
=cut

sub get_markers_for_region{
   my ($self,@args) = @_;
   
   my ( $start, $end,$chrom ) = $self->_rearrange([qw(START END CHROM)], 
						  @args);

   $start = 0 unless defined $start;
   if( !defined $end ) {
       $end = $self->map_length();
   }
   
   my $SQL = <<SQL
SELECT p.markerid from marker m, map_position p 
WHERE m.chrom = ? AND m.mapid = ?
AND m.mapid = p.mapid AND
p.position >= ? AND p.position <= ?
SQL;
		
   my ($sth,@markers);
   eval { 
       $sth = $self->prepare($SQL);
       $sth->execute($chrom,$self->id,$start,$end);       
       while( my ($markerid) = $sth->fetchrow_array) {
	   my $m = new Bio::DB::Map::SQL::MarkerAdaptor($self);
	   $m->id($markerid);
	   push @markers, $m;
       }
   };
   if( $@ ) {
       $self->throw($@);
   }
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

=head2 map_length

 Title   : map_length
 Usage   : my $len = $map->map_length()
 Function: Returns the length of the Map in the map\'s units
 Returns : float
 Args    : none


=cut

sub map_length{
   my ($self) = @_;
   
   my $SQL = sprintf("SELECT max(position) from map_position where mapid = %d",
		     $self->id);
   my ($sth,$len);
   eval { 
       $sth = $self->prepare($SQL);
       $sth->execute();
       ($len) = $sth->fetchrow_array;
       $sth->finish();
   };
   if( $@ ) {
       $self->throw($@);
   }
   return $len || '0';
}

=head2 map_units

 Title   : map_units
 Usage   : my $units = $map->map_units()
 Function: Returns the map\'s unit system (cM, cR, MB, ...)
 Returns : string
 Args    : none

=cut

sub map_units{
   my ($self) = @_;
   my $SQL = sprintf("SELECT unit from map where mapid = %d", $self->id);
   
    my ($sth,$units);
   eval { 
       $sth = $self->prepare($SQL);
       $sth->execute();
       ($units) = $sth->fetchrow_array;
       $sth->finish();
   };
   if( $@ ) {
       $self->throw($@);
   }
   return $units;
}

1;
