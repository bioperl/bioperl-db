
#
# BioPerl module for Bio::DB::Map::Marker
#
# Cared for by Jason Stajich <jason@chg.mc.duke.edu>
#
# Copyright Jason Stajich
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::DB::Map::Marker - Marker object suitable for mapping

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


package Bio::DB::Map::Marker;
use vars qw(@ISA);
use strict;

use Bio::Root::RootI;
use Bio::DB::Map::MarkerI;

@ISA = qw(Bio::DB::Map::MarkerI );

=head2 new

 Title   : new
 Usage   : my $marker = new Bio::DB::Map::Marker(@params)
 Function: 
 Returns : 
 Args    : -id    => db id,
           -locus => locus,
           -probe => probe,
           -chrom => chrom,
           -pcrfwd=> Fwd PCR primer,
           -pcrrev=> Rev PCR primer,
           -length=> product length,
           -type  => Marker type ('rh', 'msat', 'snp')
           -adaptor => Bio::DB::Map::SQL::MarkerAdaptor object
=cut

sub new { 
    my ($class,@args) = @_;
    my $self = $class->SUPER::new(@args);
    # initialize
    $self->{'_positions'} = {};    
    $self->{'_aliases'} = {};    

    my ($id,$locus,$probe,$chrom, $fwd,
	$rev,$type,$length,$adaptor) = 
	$self->_rearrange([qw(ID LOCUS PROBE CHROM 
			      PCRFWD PCRREV TYPE 
			      LENGTH ADAPTOR)],@args);
    $self->id($id);
    $self->locus($locus);
    $self->chrom($chrom);
    $self->probe($probe);
    $self->pcrfwd($fwd);
    $self->pcrrev($rev);
    $self->type($type);
    $self->length($length);
    $self->adaptor($adaptor);
    return $self;
}

=head2 add_alias

 Title   : add_alias
 Usage   : $marker->add_alias($alias,'whitehead');
 Function: adds an alias for a marker
 Returns : nothing
 Args    : alias to add, 
           source alias is from (optional)

=cut

sub add_alias {
    my($self,$alias, $src) = @_;
    if( ! $alias ) { return; }
    $self->{'_aliases'}->{$alias} = $src;    
}

=head2 get_source_for_alias

 Title   : get_source_for_alias
 Usage   : my $source = $marker->get_source_for_alias($alias);
 Function: Returns the source for a specific alias if stored
 Returns : string
 Args    : alias 

=cut

sub get_source_for_alias {
    my($self,$alias) = @_;
    return $self->{'_aliases'}->{$alias} || '';
}

=head2 is_alias

 Title   : is_alias
 Usage   : if ( $marker->is_alias($alias) )
 Function: test whether or not a specific name is an alias for a marker
 Returns : boolean
 Args    : alias

=cut

sub is_alias {
    my ($self,$name) = @_;
    foreach my $a ( $self->each_alias ) {
	return 1 if( $name =~ /$a/i );
    }
    return 0;
}

=head2 each_alias

 Title   : each_alias
 Usage   : my @aliases = $marker->each_alias();
 Function: Get a list of all the aliases for a marker
 Returns : array
 Args    : none

=cut

sub each_alias {
    my($self) = @_;
    return keys %{$self->{'_aliases'}};
}

=head2 remove_alias

 Title   : remove_alias
 Usage   : $marker->remove_alias($alias);
 Function: Remove a specific alias from a marker
 Returns : nothing
 Args    : alias

=cut

sub remove_alias {
    my ($self,$name) = @_;
    if( $self->is_alias($name)) { 
	delete $self->{'_aliases'}->{$name};
    }    
}


# perhaps abstract positions into Objects?

=head2 add_position

 Title   : add_position
 Usage   : $marker->add_position($position, $map);
 Function: Stores the position of a marker on specific map
           A marker can only have 1 position on a map
 Returns : void
 Args    : position - marker position
           map      - map name
=cut

sub add_position {
    my($self,$position,$map) = @_;
    $map = lc $map;
    $self->{'_positions'}->{$map} = $position;
}

=head2 each_positions

 Title   : each_positions
 Usage   : my @positions = $marker->each_position();
 Function: returns a list of hashes, one per map,
           Hashes have 2 keys, 'map' and 'position'
 Returns : array of hashes
 Args    : none

=cut

sub each_position {
    my($self) = @_;
    my @rval;
    foreach my $map ( keys %{$self->{'_positions'}} ) {
	push @rval, { 'map' => $map, 
		      'position' => $self->{'_positions'}->{$map} };
    }
    return @rval;
}

=head2 get_position

 Title   : get_position
 Usage   : my $pos = $marker->get_position($map);
 Function: return the position of a marker on a specific map
 Returns : position
 Args    : map name


=cut

sub get_position {
    my($self,$map) = @_;
    $map = lc $map;
    return $self->{'_positions'}->{$map};
}

=head2 id

 Title   : id
 Usage   : my $id = $marker->id
 Function: Get/Set Marker id
 Returns : integer
 Args    : integer (optional)

=cut

sub id { 
    my ($self,$value) = @_;
    if( defined $value ) {
	if( $value !~ /^\d+$/) { 
	    $self->throw("Must specify a number for the chrom");
	} 
	$self->{'_id'} = $value; 
    }
    return $self->{'_id'};
}

=head2 chrom

 Title   : chrom
 Usage   : my $chrom = $marker->chrom
 Function: Get/Set Marker Chromosome
 Returns : Chromosome value
 Args    : 1-24, X,Y (optional)

=cut

sub chrom { 
    my ($self,$value) = @_;
    if( defined $value ) { 
	$value =~ s/X/23/i;
	$value =~ s/Y/24/i;
	if( $value !~ /(\d+)$/ || 
	    ($1 < 1 || $1 > 24) ) { 
	    $self->warn("Must specify an integer [1-24] or X,Y for the chrom not ($value)");
	    $value = undef;
	} else { $value = $1; }
	$self->{'_chrom'} = $value; 
    }
    return $self->{'_chrom'};
}

=head2 locus

 Title   : locus
 Usage   : $obj->locus($newval)
 Function: 
 Example : 
 Returns : value of locus
 Args    : newvalue (optional)


=cut

sub locus{
   my ($obj,$value) = @_;
   if( defined $value) {
      $obj->{'_locus'} = $value;
    }
    return $obj->{'_locus'};
}

=head2 probe

 Title   : probe
 Usage   : $obj->probe($newval)
 Function: 
 Example : 
 Returns : value of probe
 Args    : newvalue (optional)


=cut

sub probe{
   my ($obj,$value) = @_;
   if( defined $value) {
      $obj->{'_probe'} = $value;
    }
    return $obj->{'_probe'};

}

=head2 pcrfwd

 Title   : pcrfwd
 Usage   : $obj->pcrfwd($newval)
 Function: 
 Example : 
 Returns : value of pcrfwd
 Args    : newvalue (optional)


=cut

sub pcrfwd{
   my ($obj,$value) = @_;
   if( defined $value) {
      $obj->{'_pcrfwd'} = $value;
    }
    return $obj->{'_pcrfwd'};
}

=head2 pcrrev

 Title   : pcrrev
 Usage   : $obj->pcrrev($newval)
 Function: 
 Example : 
 Returns : value of pcrrev
 Args    : newvalue (optional)


=cut

sub pcrrev{
   my ($obj,$value) = @_;
   if( defined $value) {
      $obj->{'_pcrrev'} = $value;
    }
    return $obj->{'_pcrrev'};

}

=head2 type

 Title   : type
 Usage   : $obj->type($newval)
 Function: 
 Example : 
 Returns : value of type
 Args    : newvalue (optional)


=cut

sub type{
   my ($obj,$value) = @_;
   if( defined $value) {
      $obj->{'_type'} = $value;
    }
    return $obj->{'_type'};
}

=head2 length

 Title   : length
 Usage   : $obj->length($newval)
 Function: 
 Example : 
 Returns : value of length
 Args    : newvalue (optional)


=cut

sub length{
   my ($obj,$value) = @_;
   if( defined $value) {
       if( $value !~ /(\d+)/ ) {
	   $obj->warn("must specify an integer to length");
	   $value = 0;
       } else { $value = $1; }
       
      $obj->{'length'} = $value;
    }
    return $obj->{'length'};

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
