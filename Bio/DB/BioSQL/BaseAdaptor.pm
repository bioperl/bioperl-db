
=head1 NAME

Bio::DB::SQL::BaseAdaptor - Base Adaptor for DB::SQL::adaptors

=head1 SYNOPSIS

    # base adaptor provides
    
    # SQL prepare function
    $adaptor->prepare("sql statement");

    # get of root db object
    $adaptor->db();

    # delete memory cycles
    $adaptor->deleteObj();


=head1 DESCRIPTION

This is a true base class for Adaptors in the Bio::DB::SQL
system. Original idea from Arne Stabenau (stabenau@ebi.ac.uk)

=head1 CONTACT

Describe contact details here

=head1 APPENDIX

The rest of the documentation details each of the object methods. Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::DB::SQL::BaseAdaptor;

use vars qw(@ISA);
use strict;
use Bio::Root::RootI;
use Bio::DB::SQL::BioQuery;

@ISA = qw(Bio::Root::RootI);

sub new {
    my ($class,$dbobj) = @_;

    my $self = {};
    bless $self,$class;

    if( !defined $dbobj || !ref $dbobj ) {
	$self->throw("Don't have a db [$dbobj] for new adaptor");
    }

    $self->db($dbobj);

    return $self;
}

=head2 prepare

 Title   : prepare
 Usage   : $sth = $adaptor->prepare("select yadda from blabla")
 Function: provides a DBI statement handle from the adaptor. A convience
           function so you do not have to write $adaptor->db->prepare all the
           time
 Example :
 Returns : 
 Args    :


=cut

sub prepare{
   my ($self,$string) = @_;

   return $self->db->prepare($string);
}


=head2 db

 Title   : db
 Usage   : $obj->db($newval)
 Function: 
 Returns : value of db
 Args    : newvalue (optional)


=cut

sub db{
   my $obj = shift;
   if( @_ ) {
      my $value = shift;
      $obj->{'db'} = $value;
    }
    return $obj->{'db'};

}


=head2 get_last_id

 Title   : get_last_id
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub get_last_id{
   my ($self) = @_;

   my $sth = $self->prepare("select last_insert_id()");
   my $rv  = $sth->execute;
   my $rowhash = $sth->fetchrow_hashref;
   return $rowhash->{'last_insert_id()'};
}

# turns a query string into a bioquery object
# todo; define rules for converting between querylang and
# query object
# query lang should allow passthru to sql
# BUT keep it practical
sub _get_bioquery {
    my ($self, $q) = @_;
    if (ref($q)) {
	if (ref($q) eq "HASH") {
	    $q = Bio::DB::SQL::BioQuery->new(-where=>$q->{"constraints"});
	}
	return $q;
    }
    $self->throw("query parser not implemented yet; use a hash for now");
}

sub resolve_query {
    my ($self, $query, $sqlq, @extra_where) = @_;
    
    my $qc = $query->where;
    my @wh = $self->resolve_constraint($query, $qc, $sqlq);
    if (@wh && @extra_where) {
	if (@wh > 1) {
	    warn("not what i expected.... @wh");
	}
	$sqlq->where( [(@wh, @extra_where)] );
    }
}

=head2 resolve_constraint

 Title   : resolve_constraint
 Usage   :
 Function:
 Example :
 Returns : 
 Args    : 

recursively resolves constraints; turns BioQuery constraints into
SqlQuery constraints

=cut

sub resolve_constraint {
    my ($self, $query, $qc, $sqlq) = @_;

    my @curwhere = ();    # where clause for this 

#    my $sqlqc = Bio::DB::SQL::QueryConstraint->new;

    # a query constraint can either be a leaf node
    # (eg species=Human), or it can be composite
    # eg ( c1 AND c2 AND c3 )
    # composites can only be one operand (and/or)
    # not mixed.
    if ($qc->is_composite) {

	# composite node; recursively solve for
	# the components then combine with operand;
	# (this is the 'local' part of the where clause;
	#  there is also a global part which applies to
	#  the entire query)

	my $op = $qc->operand;   # and/or
	my @subqcs = @{$qc->value};
	my @whs = ();
	foreach my $subqc (@subqcs) {
	    my @wh = $self->resolve_constraint($query, $subqc, $sqlq);
	    push(@whs, "(" . join(" And ", @wh) . ")");
	}

#	$sqlqc->operand($op);
#	$sqlqc->neg($qc->neg);
#	$sqlqc->value([@whs]);
#	$sqlqc->is_composite(1);

	if (@whs) {
	    # hmmm.... should we retain the structure in
	    # the SqlQuery object and flatten later??
	    @curwhere = ( "(" . join( " $op ", @whs) .")" );
	    if ($qc->neg) {
		@curwhere = ( "(NOT ($curwhere[0]))" );
	    }
	}
    }
    else {

	# leaf node; use the name of the constraint
	# to determine the method used to resolve it

	my $resolverh = $self->constraint_resolver;
	my $method = $resolverh->{$qc->name};
	if ($method) {

	    my @wh = &$method($self, $sqlq, $qc->value);

#	    if (scalar(@wh == 1)) {
##		$sqlqc->set($wh[0]);
##	    }
#	    else {
#		$sqlqc->operand("and");
#		$sqlqc->neg($qc->neg);
#		$sqlqc->value([@wh]);
#		$sqlqc->is_composite(1);
#	    }

	    @curwhere = @wh;
	    if ($qc->neg) {
		@curwhere = ( "(NOT (" . join( " And ", @wh) . ")" );
	    }
	}
	else {
	    $self->throw("Can't resolve constraint: '".$qc->name."'");
	}
    }

#    return $sqlqc;

    # return local part of subquery
    return @curwhere;

}


sub constraint_resolver {
    my $self = shift;
    return {};
}

sub do_query {
    my ($self, $sqlq) = @_;    
    
    my $dbh = $self->db->_db_handle;
    
    my $sql = $sqlq->getsql;
    print "SQL:$sql\n";
    my $sth = $dbh->prepare($sql);
    $sth->execute;
    return $sth;
}





1;
