
=head1 NAME

Bio::DB::SQL::BioQuery - Object representing a query on a bioperldb

=head1 SYNOPSIS

  $q = Bio::DB::SQL::BioQuery->new;
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

package Bio::DB::SQL::BioQuery;

use vars qw(@ISA);
use strict;
use Bio::DB::SQL::AbstractQuery;

@ISA = qw(Bio::DB::SQL::AbstractQuery);

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

    my $self = {};
    bless $self,$class;

    my ($object, $where, $select, $order, $group, $type) = 
	$self->_rearrange([qw(OBJECT WHERE SELECT ORDER GROUP TYPE)], @_);

    $self->datacollections($object || []);
    $self->where($where || []);
    $self->selectelts($select || []);
    $self->orderelts($order || []);
    $self->groupelts($group || []);
    $self->querytype($type || []);
    return $self;
}


=head2 querytype

  Usage:  $query->querytype($val);      # setting
      OR   return $query->querytype();  # getting

one of : select, select distinct, insert, update, delete

ignored for now...

=cut

sub querytype {
    my $self = shift;
    $self->{_querytype} = shift if @_;
    return $self->{_querytype};
}

sub as_string {
    my $self = shift;
    
}

1;





