
#
# BioPerl module for Bio::DB::Map::MapI
#
# Cared for by Jason Stajich <jason@chg.mc.duke.edu>
#
# Copyright Jason Stajich
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::DB::Map::MapI - Implementation interface of a Map

=head1 SYNOPSIS

Give standard usage here

=head1 DESCRIPTION

Describe the object here

=head1 FEEDBACK

=head2 Mailing Lists

User feedback is an integral part of the evolution of this
and other Bioperl modules. Send your comments and suggestions preferably
 to the Bioperl mailing list.
Your participation is much appreciated.

  bioperl-l@bioperl.org          - General discussion
  http://bioperl.org/MailList.shtml             - About the mailing lists

=head2 Reporting Bugs

Report bugs to the Bioperl bug tracking system to help us keep track
 the bugs and their resolution.
 Bug reports can be submitted via email or the web:

  bioperl-bugs@bioperl.org
  http://bioperl.org/bioperl-bugs/

=head1 AUTHOR - Jason Stajich

Email jason@chg.mc.duke.edu

Describe contact details here

=head1 APPENDIX

The rest of the documentation details each of the object methods. Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::DB::Map::MapI;
use vars qw(@ISA);
use strict;

use Bio::Root::RootI;
use Carp;

@ISA = qw(Bio::Root::RootI );

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
=cut

sub get_markers_for_region {
    
    $_[0]->_abstractDeath();
}

=head2 get_next_marker

 Title   : get_next_marker
 Usage   : my $marker = $map->get_next_marker(-marker => $marker,
					      -direction => 1);
 Function: returns the next marker in the map based on the given marker
           and either a positive or negative direction
 Returns : Bio::DB::Map::MarkerI object or undef 
 Args    : -marker => $marker object to start with
           -direction => [1,-1]
           -number => number of markers to retrieve
=cut

sub get_next_marker {
    $_[0]->_abstractDeath();
}

=head2 chrom_length

 Title   : chrom_length
 Usage   : my $len = $map->chrom_length()
 Function: Returns the length of a chromosome in a Map in the map\'s units
 Returns : float
 Args    : none


=cut

sub chrom_length{
   my ($self) = @_;
   $self->_abstractDeath();
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
   $self->_abstractDeath();
}

=head2 id

 Title   : id
 Usage   : $obj->id($newval)
 Function: 
 Example : 
 Returns : value of id
 Args    : newvalue (optional)

=cut

sub id {
 my ($self) = @_;
 $self->_abstractDeath();
}

=head2 name

 Title   : name
 Usage   : $obj->name($newval)
 Function: 
 Example : 
 Returns : value of name
 Args    : newvalue (optional)


=cut

sub name{
    my ($self) = @_;
    $self->_abstractDeath();
}

=head2 units

 Title   : units
 Usage   : $obj->units($newval)
 Function: 
 Example : 
 Returns : value of units
 Args    : newvalue (optional)


=cut

sub units{
    my ($self) = @_;
    $self->_abstractDeath();
}

sub _abstractDeath {
  my $self = shift;
  my $package = ref $self;
  my $caller = (caller)[1];
  
  confess "Abstract method '$caller' defined in interface Bio::DB::Map::MapI not implemented by pacakge $package. Not your fault - author of $package should be blamed!";
}

