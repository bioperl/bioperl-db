
=head1 NAME

Bio::DB::SQL::QueryConstraint - a constraint on a variable value in a query

=head1 SYNOPSIS

  # create a constraint that says "species not like drosophila*"
  my $qc = 
    Bio::DB::SQL::QueryConstraint->new(-name=>"species",
				       -op=>"like",
				       -value=>"drosophila*",
				       -neg=>1);

  # alternate way of writing same thing
  my $qc = 
    Bio::DB::SQL::QueryConstraint->new("species like drosophila*");
  $qc->neg(1);

  # use lisp-style operand-first way of specifying composites
  # species taxa id is 7227 or 7228
  my $qc = 
    Bio::DB::SQL::QueryConstraint->new("or", 
				       "species=7227", 
				       "species=7228",
				       "species=7229");

  # composite queries can also be built this way:
  my $qc = 
    Bio::DB::SQL::QueryConstraint->new(-op=>"or", 
				       value=>[$subqc1, $subqc2, $subqc3]);
  $qc->is_composite(1);

  # we can have nested constraints like this:
  my $qc = 
    Bio::DB::SQL::QueryConstraint->new("or", 
				       ["and", 
					      "species=Human", 
                                              "keywords=foo*"
                                       ],
				       ["and", 
					      "species=Drosophila virilis", 
                                              "keywords=bar*"
					]);


=head1 DESCRIPTION

represents the constraints in a query; either the whole constraints or
a part of; see the composite design patern.

the qc is a leaf node (eg Col=Val) or a composite node
(eg (AND cons1, cons2, cons3, ....)

composite nodes have name=composite

should we split this into two classes ala composite design pattern?
cramming both into one works for now.

=head1 CONTACT

Chris Mungall <cmungall@fruitfly.org>

=head1 APPENDIX

The rest of the documentation details each of the object methods. Internal methods are usually preceded with a _

=cut


# Let the code begin...

package Bio::DB::SQL::QueryConstraint;

use vars qw(@ISA);
use strict;
use Bio::Root::RootI;

@ISA = qw(Bio::Root::RootI);

sub new {
    my $class = shift;

    my $self = {};

    bless $self,$class;
    my ($str, $name, $op, $value, $neg) = 
	$self->_rearrange([qw(STR NAME OP VALUE NEG)], @_);
    $self->set($str) if defined($str);
    $self->name($name) if defined($name);
    $self->operand($op) if defined($op);
    $self->value($value) if defined($value);
    $self->neg($neg) if defined($neg);
    return $self;
}

sub set {
    my $self = shift;
    my $arg = shift;
    my @comp = ();
    if (ref($arg)) {
	my @subqcs = ();
	my $op = "and";
	if (ref($arg) eq "HASH") {
	    foreach my $k (keys %$arg) {
		my $subqc = 
		  Bio::DB::SQL::QueryConstraint->new(-name=>$k, -value=>$arg->{$k});
		push(@subqcs, $subqc);
	    }
	}
	if (ref($arg) eq "ARRAY") {
	    if (grep {lc($arg->[0]) eq $_} qw(and or)) {
		$op = shift @$arg;
	    }
	    foreach my $el (@$arg) {
		if (ref($el) &&
		    ref($el) eq "ARRAY") {
		    my $subqc = 
		      Bio::DB::SQL::QueryConstraint->new($el);
		    push(@subqcs, $subqc);
		}
		elsif (ref($el) &&
		    ref($el) ne "HASH" &&
		    $el->isa("Bio::DB::SQL::QueryConstraint")) {
		    push(@subqcs, $el);
		}
		elsif ($el =~ / *(.*) *(=|like) *(.*) */) {
		    my $subqc = 
		      Bio::DB::SQL::QueryConstraint->new(-name=>$1, 
							 -op=>$2,
							 -value=>$3);
		    push(@subqcs, $subqc);
		}
		else {
		    $self->throw("$el not parseable");
		}
	    }
	}
	if (scalar(@subqcs) == 1) {
	    # only one subcomponent;
	    # dont need to make a composite
	    %{$self} = %{$subqcs[0]};
	}
	else {
	    # composite
	    $self->operand($op);
	    $self->value(\@subqcs);
	    $self->is_composite(1);
	}
    }
    else {
	# $arg is a string
	if ($arg =~ / *(.*) *([=|like]) *(.*) */) {	
	    $self->name($1);
	    $self->operand($2);
	    $self->value($3);
	}
	else {
	    $self->throw("Can't parse string $arg");
	}
    }
}


=head2 name

  Usage:  $qc->name($val);      # setting
      OR   return $qc->name();  # getting

the name of the variable being constrained

=cut

sub name {
    my $self = shift;
    if (@_) {
	my $n = shift;
	$n =~ s/^ *//g;
	$n =~ s/ *$//g;
	$self->{_name} = $n;
    }
    return $self->{_name};
}

=head2 value

  Usage:  $qc->value($val);      # setting
      OR   return $qc->value();  # getting

the value of the variable is allowed to take mediated by the operand

this is an arrayref of sub-constraints if this a composite

=cut

sub value {
    my $self = shift;
    $self->{_value} = shift if @_;
    return $self->{_value};
}

=head2 operand

  Usage:  $qc->operand($val);      # setting
      OR   return $qc->operand();  # getting

defaults to "="

=cut

sub operand {
    my $self = shift;
    $self->{_operand} = shift if @_;
    return $self->{_operand};
}

=head2 neg

  Usage:  $qc->neg($val);      # setting
       OR   return $qc->neg();  # getting

boolean

set if the constraint is to be negated

=cut

sub neg {
    my $self = shift;
    $self->{_neg} = shift if @_;
    return $self->{_neg};
}

=head2 is_composite

  Usage:  $qc->is_composite($val);       # setting
       OR   return $qc->is_composite();  # getting

boolean

set if the constraint is a composite constraint

(in this case the sub constraints go in $qc->values)

=cut

sub is_composite {
    my $self = shift;
    if (@_) {
	my $v = shift;
	if ($v) {
	    # is this bad? overloading name attribute
	    $self->{_name} = "composite";
	}
    }
    return $self->{_name} eq "composite";
}


1;





