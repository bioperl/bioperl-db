
=head1 NAME

Bio::DB::SQL::AbstractQuery - Abstract Query class

=head1 SYNOPSIS

Don't use this class directly; use one of the subclasses (eg SqlQuery,
BioQuery)

  $q = $queryclass->new;
  $q->datacollections(["table1 t1", "table2 t2"]);
  $q->selectelts(["t1.colA", "t2.colB"]);
  $q->where("or", "colA=x", "colB=y");
  $q->orderelts(["t1.colA", "t2.colB"]);

=head1 DESCRIPTION

core methods for representing some kind of query - eg a query
expressed in an human type language, an SQL query, an object oriented
query.

abstracted attribute names have been used; eg a query is assumed to be
over some kind of collection of data. the query is performed over a
subset of this data, a set of datacollections. These datacollections
are equivalent to tables in SQL and object adaptors when forming an OO
query.

the where clause / constraints is represented by the QueryConstraint
composite object

=head1 CONTACT

Chris Mungall <cmungall@fruitfly.org>

=head1 APPENDIX

The rest of the documentation details each of the object methods. Internal methods are usually preceded with a _

=cut


# Let the code begin...

package Bio::DB::SQL::AbstractQuery;

use vars qw(@ISA);
use strict;
use Bio::Root::RootI;
use Bio::DB::SQL::QueryConstraint;

@ISA = qw(Bio::Root::RootI);

sub new {
    my $class = shift;

    my $self = {};
    bless $self,$class;

    my ($datacollection, $where, $select, $order, $group, $type, $bio) = 
	$self->_rearrange([qw(DATACOLLECTION WHERE SELECT ORDER GROUP TYPE BIO)], @_);

    $self->datacollections($datacollection || []);
    $self->where($where || []);
    $self->selectelts($select || []);
    $self->orderelts($order || []);
    $self->groupelts($group || []);
    $self->querytype($type || []);
    $self->{_flags} = {};
    return $self;
}

sub flag  {
    my $self = shift;
    my ($flag, $val) = @_;
    if (defined($val)) {
	$self->{_flags}->{$flag} = $val;
    }
    return  $self->{_flags}->{$flag};
}

=head2 datacollections

  Usage:  $query->datacollections([$t1,$t2]);      # setting
      OR   return $query->datacollections();  # getting

array reference of strings representing datacollections (eg tables,
objects)

=cut

sub datacollections {
    my $self = shift;
    $self->{_datacollections} = $self->make_arrayref(@_) if @_;
    return $self->{_datacollections};
}

=head2 add_datacollection

  Usage:  $query->add_datacollection($t1, $t2, $t3);

adds datacollections; removes duplicates

=cut

sub add_datacollection {
    my $self = shift;
    my @to_add = @_;
    foreach my $dc (@to_add) {
	unless (grep {$dc eq $_} @{$self->datacollections}) {
	    push(@{$self->datacollections}, $dc);
	}
    }
}

=head2 where

  Usage:  $query->where("and", "att1 = val1", "att2=val2"); # setting
      OR  $query->where("att1 = val1"); # setting
      OR  $query->where({att1=>$val1, att2=>$val2}); # setting
      OR  $query->where(["OR",
                              ["AND",
                                     "x=1", "y=2", "z like blah*"],
                              ["AND",
                                     "x=5", "y=7", "z like wow*"]]);
 
      OR   $qc = $query->where();  # getting

 of type Bio::DB::SQL::QueryConstraint

this method is liberal in what it accepts. 

see the new() method of Bio::DB::SQL::QueryConstraint

it will turn hashes into an ANDed query constraint composite, with
each component being a name=value pair. it will turn arrays into an
ANDed constraint composite, breaking up each element around the =
symbol. if the first element of the array is a valid composite operand
(e.g. "or") it will combine the array elements using this.

Or you can just feed it a Bio::DB::SQL::QueryConstraint object

=cut

sub where {
    my $self = shift;
    if (@_) {
	my $arg;
	if (@_ > 1) {
	    $arg = [@_];    # turn any nonscalar into arrayref
	}
	else {
	    $arg = shift;
	}
	my $qc = Bio::DB::SQL::QueryConstraint->new($arg);
	$self->{_where} = $qc;
    }

    return $self->{_where};
}

#sub add_where {
#    my $self = shift;
#    push(@{$self->where}, @_);
#}

=head2 selectelts

  Usage:  $query->selectelts([$col1,$col2,$col3]);      # setting
      OR  $eltsref = $query->selectelts();  # getting

array reference of string represnting attributes/elements to be
selected

=cut

sub selectelts {
    my $self = shift;
    $self->{_selectelts} = $self->make_arrayref(@_) if @_;
    return $self->{_selectelts};
}


=head2 orderelts

  Usage:  $query->orderelts(\@elts);      # setting
      OR   return $query->orderelts();  # getting

=cut

sub orderelts {
    my $self = shift;
    $self->{_orderelts} = $self->make_arrayref(@_) if @_;
    return $self->{_orderelts};
}


=head2 groupelts

  Usage:  $query->groupelts(\@elts);      # setting
      OR   return $query->groupelts();  # getting

=cut

sub groupelts {
    my $self = shift;
    $self->{_groupelts} = $self->make_arrayref(@_) if @_;
    return $self->{_groupelts};
}

# turns arrays into arrayrefs
# turns strings to arrays by breaking on commas
# if passed an arrayref, will leave it alone
sub make_arrayref {
    my $self = shift;

    if (scalar(@_) > 1) {
	return [@_];
    }

    my $v = shift;
    if (ref($v)) {
	return $v;
    }
    else {
	my @arr = split(/\,/, $v);
	map {s/ *$//;s/^ *//g} @arr;
	return [@arr];
    }
}


sub flatten_qc {
    my $self = shift;
    my $qc = shift;
    my $flat;
    if ($qc->is_composite) {
	my @subqcs = ();
	foreach my $subqc (@{$qc->value}) {
	    push(@subqcs, $self->flatten_qc($subqc));
	}
	$flat = 
	    join(" ".$qc->operand." ",
		 @subqcs);
	if (@subqcs > 1) {
	    $flat = "($flat)";
	}
    }
    else {
	$flat =
	    sprintf("%s %s %s",
		    $qc->name,
		    $qc->operand || "=",
		    $qc->value);
	if ($qc->neg) {
	    $flat = "(NOT $flat)";
	}
    }
    return $flat;
}


1;





