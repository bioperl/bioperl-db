
#
# BioPerl module for Bio::DB::Map::MarkerI
#
# Cared for by Jason Stajich <jason@chg.mc.duke.edu>
#
# Copyright Jason Stajich
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::DB::Map::MarkerI - Interface of Marker objects

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

package Bio::DB::Map::MarkerI;
use vars qw(@ISA);
use strict;

use Bio::Root::RootI;
use Carp;
@ISA = qw(Bio::Root::RootI);


sub to_string {
    my ($self) = @_;
    
    return join("\n", (sprintf("LOCUS: %s", $self->locus || ''),
		       sprintf("PROBE: %s", $self->probe || ''),
		       sprintf("CHROM: %s", $self->chrom || ''),
		       sprintf("TYPE : %s", $self->type || ''),
		       sprintf("FWDP : %s", $self->pcrfwd || ''),
		       sprintf("REVP : %s", $self->pcrrev || '' ),
		       sprintf("LEN  : %s", $self->length || '?') )
		      );
}

=head2 add_alias

 Title   : add_alias
 Usage   : $marker->add_alias($alias,'whitehead');
 Function: adds an alias for a marker
 Returns : nothing
 Args    : alias to add, 
           map name alias is from (optional)

=cut

sub add_alias {
    my($self,$alias, $map) = @_;
    $self->abstractDeath();
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
    $self->_abstractDeath();
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
    $self->abstractDeath();
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
    $self->abstractDeath();
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
    $self->abstractDeath();
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
    $self->abstractDeath();
}

=head2 each_position

 Title   : each_position
 Usage   : my @positions = $marker->each_position();
 Function: returns a list of hashes, one per map,
           Hashes have 2 keys, 'map' and 'position'
 Returns : array of hashes
 Args    : none

=cut

sub each_position {
    my($self) = @_;
    $self->_abstractDeath();
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
    $self->_abstractDeath();
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
    $self->_abstractDeath();
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
    $self->_abstractDeath();
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
    $obj->_abstractDeath();
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
    $obj->_abstractDeath();
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
    my ($obj) = @_;
    $obj->_abstractDeath();
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
    my ($obj) = @_;
    $obj->_abstractDeath();
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
    my ($self) = @_;
    $self->_abstractDeath();
}


sub _abstractDeath {
  my $self = shift;
  my $package = ref $self;
  my $caller = (caller)[1];
  
  confess "Abstract method '$caller' defined in interface Bio::DB::Map::MarkerI not implemented by pacakge $package. Not your fault - author of $package should be blamed!";
}


1;

