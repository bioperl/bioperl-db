
#
# BioPerl module for Bio::DB::Map::Map
#
# Cared for by Jason Stajich <jason@chg.mc.duke.edu>
#
# Copyright Jason Stajich
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::DB::Map::Map - DESCRIPTION of Object

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

package Bio::DB::Map::Map;
use vars qw(@ISA);
use strict;

# Object preamble - inherits from Bio::Root::RootI

use Bio::Root::RootI;
use Bio::DB::Map::MapI;

@ISA = qw(Bio::DB::Map::MapI Bio::Root::RootI );

sub new {
    my($class,@args) = @_;
        my $self = $class->SUPER::new(@args);
    my ($mapname,$mapunits,
	$id, $adaptor) = $self->_rearrange([qw(NAME 
					       UNITS 
					       ID
					       ADAPTOR)],@args);

    $self->adaptor($adaptor);
    $self->id     ($id);
    $self->units  ($mapunits);
    $self->name   ($mapname);

    return $self;
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
       $end = $self->chrom_length($self->id, $chrom);
   }

   my @markers = $self->adaptor->get_markers_for_region('-id'    => $self->id,
							'-start' => $start,
							'-end'   => $end,
							'-chrom' => $chrom);
   return @markers;
}

=head2 get_next_marker

 Title   : get_next_marker
 Usage   : my $marker = $map->get_next_marker(-marker    => $marker,
					      -direction => 1);
 Function: returns the next marker in the map based on the given marker
           and either a positive or negative direction
 Returns : Bio::DB::Map::MarkerI object or undef 
 Args    : -marker    => $marker Bio::DB::Map::MarkerI object to start with
           -direction => [1,-1]
           -number    => number of markers to retrieve
=cut

sub get_next_marker {
    my ($self,@args) = @_;
    my ($marker,$direction,$number) = $self->_rearrange([qw(MARKER DIRECTION NUMBER)],
							@args);
    my @markers = $self->adaptor->get_next_marker('-markerid'  => $marker->id,
				    '-mapid'     => $self->id,
				    '-direction' => $direction,
				    '-number'    => $number);
    return @markers;
}

=head2 chrom_length

 Title   : chrom_length
 Usage   : my $len = $map->chrom_length()
 Function: Returns the length of a chromosome in a Map in the map\'s units
 Returns : float
 Args    : none

=cut

sub chrom_length{
   my ($self,$chrom) = @_;
   return 0 unless defined $chrom;
   $chrom =~ s/(chr)?(X|Y|\d+)/$2/;
   $chrom =~ s/X/23/;
   $chrom =~ s/Y/24/;   
   return $self->adaptor->get_Chrom_length($self->id, $chrom);
}

=head2 Get/Set Methods

=head2 id

 Title   : id
 Usage   : $obj->id($newval)
 Function: 
 Example : 
 Returns : value of id
 Args    : newvalue (optional)

=cut

sub id {
   my ($obj,$value) = @_;
   if( defined $value) {
      $obj->{'_id'} = $value;
    }
    return $obj->{'_id'};
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
   my ($obj,$value) = @_;
   if( defined $value) {
      $obj->{'name'} = $value;
    }
    return $obj->{'name'};
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
   my ($obj,$value) = @_;
   if( defined $value) {
      $obj->{'units'} = $value;
    }
    return $obj->{'units'};

}

=head2 adaptor

 Title   : adaptor
 Usage   : $obj->adaptor($newval)
 Function: 
 Example : 
 Returns : value of adaptor
 Args    : newvalue (optional)

=cut

sub adaptor {
   my ($obj,$value) = @_;
   if( defined $value) {
      $obj->{'adaptor'} = $value;
    }
    return $obj->{'adaptor'};

}

1;
