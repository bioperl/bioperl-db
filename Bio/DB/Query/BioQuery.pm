# $Id$

#
# Copyright Chris Mungall <cmungall@fruitfly.org>
#
# You may use, copy, modify, and redistribute this module under the same terms
# as Perl itself.
#

=head1 NAME

Bio::DB::Query::BioQuery - Object representing a query on a bioperldb

=head1 SYNOPSIS

  $q = Bio::DB::Query::BioQuery->new;
  $q->where(["AND", "attA=x", "attB=y", "attC=y"]);
  $adaptor->fetch_by_query($q);

=head1 DESCRIPTION

A BioQuery is a high level query on a biological database. It allows
queries to be specified regardelss of the underlying schema. Although
a BioQuery can be translated into a corresponding SqlQuery or series
of SqlQuerys, it is not always desirable to do so; rather the BioQuery
should be translated into SqlQuerys one at a time, the SqlQuery
executed and the results fed back to the BioQuery processor.

It is the job of the various adaptors to turn BioQuerys into resulting
Bio objects via these transformations.

A BioQuery can be specified either as a text string which is converted
into a BioQuery object via some grammar, or the object can be created
and manipulated directly. The text string would be some kind of
sqlesque language, one can imagine different languages with different
grammars.

Other than being more high level, a BioQuery differs from a SqlQuery
in that it is object based, not table based.

the BioQuery is a schema independent repesentation of a query; it may
or may not be tied to the bioperl object model.

=head1 STATUS

There is no parser to turn statements like

  "FETCH Seq.* from Seq where species='Human'"

into a BioQuery object; objects have to be built manually

At the moment, everything in this object apart from the query
constraints (the $bioquery->where() method) are ignored.


=head1 CONTACT

Chris Mungall <cmungall@fruitfly.org>

=head1 APPENDIX

The rest of the documentation details each of the object methods. Internal methods are usually preceded with a _

=cut


# Let the code begin...

package Bio::DB::Query::BioQuery;

use vars qw(@ISA);
use strict;
use Bio::DB::Query::AbstractQuery;

@ISA = qw(Bio::DB::Query::AbstractQuery);

=head2 new

  Usage:  $bioq = $self->new("SELECT bioentry.* FROM bioentry WHERE species='Human'");  # NOT IMPLEMENTED
      OR  $bioq = $self->new(-select=>["att1", "att2"],
			     -where=>["att3='val1'", "att4='val4'"]);
      OR  $bioq = $self->new(-where=>{species=>'human'});

  Args: objects, where, select, order, group

all arguments are optional (select defaults to *)

the arguments can either be array references or a comma delimited string

the where argument can also be passed as a hash reference

the from/objects array is optional because this is usually derived
from the context eg the database adapter used. if used outside this
context the object is required.

=cut

sub new {
    my $class = shift;

    my $self = $class->SUPER::new(@_);

    my ($object) = $self->_rearrange([qw(OBJECT)], @_);

    $self->datacollections($object)
	if $object && (! @{$self->datacollections()});

    return $self;
}

=head2 translate_query

 Title   : translate_query
 Usage   :
 Function: Translates this query from objects and class names and
           slot names to tables and column names.

           You will most likely have to call this method before being
           able to generate meaningful SQL from a BioQuery object.

 Example :
 Returns : An object of the same class as this query, but representing
           the translated query.
 Args    : The L<Bio::DB::Persistent::ObjectRelMapperI> to use.
           Optionally, a reference to an empty hash. If provided, upon
           return it will hold a mapping from tables to aliases.

Contact Hilmar Lapp <hlapp at gmx.net> for questions, bugs, flames,
praises etc.

=cut

sub translate_query{
    my ($self,$mapper,$entitymap) = @_;

    # first off, clone the query in order to keep the original untouched
    my $tquery = {};
    %$tquery = %$self;
    bless $tquery, ref($self);
    # initialize some variables
    $entitymap = {} unless $entitymap;
    my $aliasmap = {};
    my @joins = ();
    my @tablelist = ();
    my $tbl;
    # determine the tables, and simultaneously the necessary joins
    foreach (@{$tquery->datacollections()}) {
	# it may (hopefully does) come with an alias
	my ($entity,$alias) = split(/\s+/, $_);
	# this may be a FK-linked table or an assocation
	if($entity =~ /<=>/) {
	    # it's an association
	    my @entities = split(/<=>/, $entity);
	    my %ent_counts = map { ($_,0); } @entities;
	    #foreach (@entities) { $ent_counts{$_}++; }
	    # determine the association table
	    my $assoc = $mapper->association_table_name(\@entities);
	    if(! $assoc) {
		$self->throw("failed to map (".join(",",@entities).
			     ") to an association table");
	    }
	    # record the association table alias
	    $entitymap->{$assoc} = [$alias || $assoc];
	    # resolve all participating entities to table names; at the same
	    # time we need foreign keys to all participating entities
	    for(my $i = 0; $i < @entities; $i++) {
		$tbl = $mapper->table_name($entities[$i]);
 		$self->throw("failed to map $entities[$i] to a table")
		    unless $tbl;
		$ent_counts{$entities[$i]}++;
		# record alias and add entity to the datacollections if it
		# hasn't been done yet
		$entitymap->{$tbl} = [] unless exists($entitymap->{$tbl});
		if(! exists($aliasmap->{$entities[$i]})) {
		    push(@{$entitymap->{$tbl}}, $tbl);
		    $aliasmap->{$entities[$i]} = $tbl;
		    $aliasmap->{$tbl} = $tbl;
		    push(@tablelist, $tbl);
		}
		# add join to association table
		my $pk = $mapper->primary_key_name($tbl);
 		$self->throw("failed to map $tbl to primary key") unless $pk;
		my @tblalias =
		    split(/::/,
			  $entitymap->{$tbl}->[$ent_counts{$entities[$i]}-1]);
		my $fkent = $entities[$i];
		$fkent .= "::".$tblalias[1] if @tblalias > 1;
		my $fk = $mapper->foreign_key_name($fkent);
 		$self->throw("failed to map $fkent to a FK") unless $fk;
		push(@joins,
		     $tblalias[0] .".". $pk ." = ".
		     $entitymap->{$assoc}->[0] .".". $fk);
	    }
	    # and finally add association table
	    push(@tablelist, $assoc . ($alias ? " $alias" : ""));
 	} elsif($entity =~ /[<=>]{2}/) {
	    # it's a FK relationship
	    my ($parent,$child) = split(/[<=>]{2}/, $entity);
	    my %aliases = ();
	    if($entity =~ /=>/) {
		# parent was first, hence alias refers to it
		$aliases{$parent} = $alias;
	    } else {
		# reverse the order (child was first, and the alias referred
		# to the child)
		$tbl = $parent; $parent = $child; $child = $tbl;
		$aliases{$child} = $alias;
	    }
	    # resolve parent and child to their table names
	    my $ptbl;
	    foreach my $ent ($child, $parent) {
		$tbl = $mapper->table_name($ent);
		$ptbl = $tbl if $ent eq $parent;
		$self->throw("failed to map $ent to a table") unless $tbl;
		# store aliases and datacollections
		$entitymap->{$tbl} = [] unless exists($entitymap->{$tbl});
		$aliases{$ent} = $tbl unless $aliases{$ent};
		if(! exists($aliasmap->{$ent})) {
		    push(@{$entitymap->{$tbl}}, $aliases{$ent});
		    $aliasmap->{$ent} = $aliases{$ent};
		    $aliasmap->{$aliases{$ent}} = $tbl;
		    push(@tablelist,
			 $tbl .
			 ($aliases{$ent} ne $tbl ? ' '.$aliases{$ent} : ""));
		}
	    }
	    # determine columns for the join (foreign key of child, primary
	    # key of parent), and add constraint to the list
	    my $fk = $mapper->foreign_key_name($parent);
	    my $pk = $mapper->primary_key_name($ptbl);
	    push(@joins,
		 $aliasmap->{$child} .".". $fk ." = ".
		 $aliasmap->{$parent} .".". $pk);
	} else {
	    # "simple" table
	    $tbl = $mapper->table_name($entity);
	    $self->throw("failed to map $entity to a table") unless $tbl;
	    # add to data collections while preventing duplicates
	    $entitymap->{$tbl} = [] unless exists($entitymap->{$tbl});
	    $alias = $tbl unless $alias;
	    if(! exists($aliasmap->{$alias})) {
		push(@{$entitymap->{$tbl}}, $alias);
		$aliasmap->{$entity} = $alias unless $aliasmap->{$entity};
		$aliasmap->{$alias} = $tbl;
		if($alias && (index($alias, '::') >= 0)) {
		    ($alias) = split(/::/, $alias);
		    $aliasmap->{$alias} = $tbl;
		}
		push(@tablelist, $tbl . ($alias ne $tbl ? " $alias" : ""));
	    }
	    # we don't need a join here
	}
    }
    # Entity map maps tables to their aliases. For translating column names
    # we need the reverse map alias->table.
    #while(my @pair = each %$entitymap) { $aliasmap->{$pair[1]} = $pair[0]; }
    # map the slots to columns in the constraints and prepend joins to WHERE
    if($tquery->where()) {
	# map slots to columns
	my $wc = $self->_map_constraint_slots_to_columns($tquery->where(),
							 $aliasmap,
							 $mapper);
	# prepend joins to translated constraint
	push(@joins, $wc);
    }
    $tquery->where(["and", @joins]);
    # replace datacollections
    $tquery->datacollections(\@tablelist);
    # map SELECT fields to columns
    my $sels = $tquery->selectelts();
    if($sels && @$sels) {
	$tquery->selectelts($self->_map_select_slots_to_columns($sels,
								$aliasmap,
								$mapper));
    }
    # before we return we'll add the reverse map (alias->entity) to the
    # entity map as well
    #@{$entitymap}{(keys %aliasmap)} = values %aliasmap;
    # done
    return $tquery;
}

sub _map_constraint_slots_to_columns{
    my ($self,$constraint,$aliasmap,$mapper) = @_;

    # first, clone it
    my $mcons = {};
    %$mcons = %$constraint;
    bless $mcons, ref($constraint);
    # is it a composite constraint (i.e., contains sub-constraints?)
    if($mcons->is_composite()) {
	# map each of the sub-constraints recursively and replace with the
	# mapped one
	my $qcs = $mcons->value();
	for(my $i = 0; $i < @$qcs; $i++) {
	    $qcs->[$i] = $self->_map_constraint_slots_to_columns($qcs->[$i],
								 $aliasmap,
								 $mapper);
	}
    } else {
	# no, this one's a flat tuple (name, operator, value)
	#
	my ($alias,$slot);
	my @ns = split(/\./, $mcons->name());         # dot takes precedence
	@ns = split(/::/, $mcons->name()) if @ns < 2; # but full path is OK too
	$slot = pop(@ns);
	$alias = join("::", @ns); # if dot was delimiter, scalar(@ns) == 1 now
	# we only need to change the slot name
	($slot, $alias) = $self->_map_slot_to_col($slot, $alias,
						  $aliasmap, $mapper);
	# set column name; if this is not mapped (intentionally, indicated
	# by being mapped to undef), make the condition behave neutral by
	# always being true
	if($slot) {
	    $mcons->name($alias .".". $slot);
	} else {
	    $mcons->name("1");
	    $mcons->operand("=");
	    $mcons->value("1");
	}
    }
    # this should be it ...
    return $mcons;
}

sub _map_select_slots_to_columns{
    my ($self,$selectcols,$aliasmap,$mapper) = @_;

    # first, clone the array
    my $selcols = [@$selectcols];
    # loop over all columns and map from slot to column
    for(my $i; $i < @$selcols; $i++) {
	# match a pattern to locate alias.slot instead of assuming that the
	# entire string is what we are looking for
	my @pats = ('([\w0-9_]+)\.([\w0-9_]+)()',
		    '()([\w0-9_]+)([\s\),\/\*\+\-])',
		    '(^)(.*)($)');
	my ($pat,$alias,$slot);
	while(@pats) {
	    $pat = shift(@pats);
	    if($selcols->[$i] =~ /$pat/) {
		$alias = $1;
		$slot = $2;
		last;
	    }
	}
	$self->throw("unable to extract slot name from ".$selcols->[$i])
	    unless $pat;
	# obtain mapped column name
	($slot,$alias) = $self->_map_slot_to_col($slot, $alias,
						 $aliasmap, $mapper);
	# replace with mapped column name
	my $mappedcol = $slot ? $alias.".".$slot : "NULL";
	$selcols->[$i] =~ s/$pat/${mappedcol}$3/;
    }
    return $selcols;
}

sub _map_slot_to_col{
    my ($self,$slot,$alias,$aliasmap,$mapper) = @_;

    if(! $alias) {
	# great, no alias. WTF didn't read the docs? How am I supposed to
	# know to which entity it belongs? OK, we'll try and be a
	# smart ass:
	# 1) if there's only one entity, it's got to be that one, or
	# 2) if there are multiple, but there's only one without an alias,
	# we'll use that one
	my @keys = keys %$aliasmap;
	if(@keys > 1) {
	    @keys = grep { $aliasmap->{$_} eq $_; } @keys;
	}
	if(@keys == 1) {
	    $alias = $keys[0];
	} else {
	    $self->throw("Unable to unambiguously infer which entity ".
			 "'$slot' refers to. Prefix it with an entity alias.");
	}
    }
    # obtain the entity name (table name)
    my $tbl = $aliasmap->{$alias};
    if($tbl) {
	# map once more if the table is another alias instead
	if(exists($aliasmap->{$tbl})) {
	    $alias = $tbl;
	    $tbl = $aliasmap->{$tbl};
	}
    } elsif(index($alias,'::') >= 0) {
	# Looks like a class name. This could be unresolved due to an
	# adaptor name being used in the data collections, and the class
	# being used in a constraint (or select column). We ask the mapper
	# to resolve this.
	$tbl = $mapper->table_name($alias);
	# try to find the alias for it
	if($tbl) {
	    my @keys = grep {
		($aliasmap->{$_} eq $tbl) && (index($_,'::') < 0);
	    } keys %$aliasmap;
	    if(@keys == 1) {
		$alias = $keys[0];
	    } else {
		$alias = $tbl;
	    }
	}
    }
    if(! $tbl) {
	$self->throw("Alias \"$alias\" not mapped to entity. ".
		     "Are you sure there's no typo?");
    }
    # treat the literal 'primary_key' special in that it refers to the name of
    # the primary key
    my $col;
    if($slot eq "primary_key") {
	$col = $mapper->primary_key_name($tbl);
    } else {
	# map the slot to the respective column in the table
	my $slotmap = $mapper->slot_attribute_map($tbl);
	$self->throw("failed to obtain slot-attribute map for table $tbl")
	    unless $slotmap;
	if(exists($slotmap->{$slot})) {
	    $col = $slotmap->{$slot};
	} else {
	    # Hmm - not mapped. Maybe it's a class or adaptor name and refers
	    # to a foreign key.
	    $col = $mapper->foreign_key_name($slot);
	    # if that didn't work we throw our hands up
	    $self->throw("slot '$slot' not mapped to column for table $tbl")
		unless $col;
	}
    }
    # done
    return ($col,$alias);
}

1;
