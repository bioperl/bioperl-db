

#
# BioPerl module for Bio::DB::SQL::SeqAdaptor
#
# Cared for by Ewan Birney <birney@ebi.ac.uk>
#
# Copyright Ewan Birney
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::DB::SQL::SeqAdaptor - DESCRIPTION of Object

=head1 SYNOPSIS

Give standard usage here

=head1 DESCRIPTION

Describe the object here

=head1 FEEDBACK

=head2 Mailing Lists

User feedback is an integral part of the evolution of this
and other Bioperl modules. Send your comments and suggestions preferably
 to one of the Bioperl mailing lists.
Your participation is much appreciated.

  bioperl-l@bio.perl.org

=head2 Reporting Bugs

Report bugs to the Bioperl bug tracking system to help us keep track
 the bugs and their resolution.
 Bug reports can be submitted via email or the web:

  bioperl-bugs@bio.perl.org
  http://bio.perl.org/bioperl-bugs/

=head1 AUTHOR - Ewan Birney

Email birney@ebi.ac.uk

Describe contact details here

=head1 APPENDIX

The rest of the documentation details each of the object methods. Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::DB::SQL::SeqAdaptor;
use vars qw(@ISA);
use strict;


use Bio::DB::Seq;
use Bio::DB::SQL::BaseAdaptor;
use Bio::DB::SQL::SqlQuery;


@ISA = qw(Bio::DB::SQL::BaseAdaptor);

# new is from Bio::DB::SQL::Adaptor

=head2 fetch_by_dbID

 Title   : fetch_by_dbID
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub fetch_by_dbID{
   my ($self,$id) = @_;

   if( !defined $id || $id !~ /^\d+$/) {
       $self->throw("Must have an id to fetch by id! (and it must be a number not [$id])");
   }

   #print STDERR "select en.display_id,en.accession,en.entry_version,length(bs.biosequence_str),bs.molecule,en.division from bioentry en,biosequence bs where bs.bioentry_id = en.bioentry_id and bs.bioentry_id = $id\n";

   my $sth = $self->prepare("select en.display_id,en.accession,en.entry_version,length(bs.biosequence_str),bs.molecule,en.division,bed.description from bioentry en,biosequence bs,bioentry_description bed where bed.bioentry_id=en.bioentry_id and bs.bioentry_id = en.bioentry_id and bs.bioentry_id = $id");

   $sth->execute;

   my ($display,$acc,$version,$len,$mol,$div,$desc) = $sth->fetchrow_array;

   if( !defined $display ) {
       $self->throw("Bioentry id $id does not have a biosequence or bioentry ");
   }

   return Bio::DB::Seq->new( -primary_id => $id,
			     -display_id => $display,
			     -accession  => $acc,
			     -version    => $version,
			     '-length'   => $len,
			     -moltype   => $mol,
			     -division   => $div,
			     -desc       => $desc,
			     -adaptor    => $self);
   

}



=head2 fetch_by_db_and_accession

 Title   : fetch_by_db_and_accession
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub fetch_by_db_and_accession{
   my ($self,$db,$accession) = @_;

   my $sth = $self->prepare("select en.bioentry_id from bioentry en, biodatabase biodb where biodb.name = '$db' AND en.biodatabase_id = biodb.biodatabase_id AND en.accession = '$accession'");
   $sth->execute;

   my ($enid) = $sth->fetchrow_array();

   if( defined $enid ) {
       # this is not well optimised. We could share common object building code here.
       return $self->fetch_by_dbID($enid);
   } else {
       $self->throw("Unable to retrieve sequence with $db and $accession");
   }
   
}

=head2 fetch_by_query

 Title   : fetch_by_query
 Usage   : @seqs = $seqadp->fetch_by_query($bioquery);
 Function:
 Example : @seqs = 
            $seqadp->fetch_by_query(-constraints=>
              ["or",
                   ["and",
                         "species=Human",
                         "keywords=transcription*"],
                   ["and",
                         "species like Drosophila*",
                         "description like *integrase*"],
	       ]);
 Returns : list of Bio::Seq objects
 Args    : BioQuery object OR hash reference

Takes a Bio::DB::SQL::BioQuery object, or arguments that can be used
to construct one. Right now only the constraints/where part is
respected.

Executes the BioQuery by turning the query into individual SqlQuerys
(although we could have non-sql adaptors conforming to the same
interface as this one, and have the BioQuery translated in some other
way)

the BioQuery is a schema independent repesentation of a query; it may
or may not be tied to the bioperl object model.

These are the constraint elements that are currently accepted:

(THESE ARE SUBJECT TO CHANGE)

=over

=item species

This can either by a Bio::Species object, or an NCBI taxonomy ID, or a
common_name for the species

=item references

A string

=item keywords

A string

=item description

A string

=back

For all the above constraints, specifying the wildcard character * in
the string will automatically make the query use pattern matching
(replacing * for % in the sql query, and use the like operand) rather
than exact matches.

eg to query by species

    $bioquery = Bio::DB::SQL::BioQuery->new();
    $qc = Bio::DB::SQL::QueryConstraint->new(-name=>"species",
					     -value=>$species);
    $bioquery->where($qc);
    @seqs=$seqadp->fetch_by_query($bioquery);

or simply

    @seqs=$seqadp->fetch_by_query(-constraints=>"species = $species");

at some point we may want to make the BioQuerys more sql-like, by
allowing constraints by Class+attribute like this:

  @seqs=$seqadp->fetch_by_query(-constraints=>"Species.common_name = Human");
  @seqs=$seqadp->fetch_by_query(-constraints=>"Reference.authors = *Shuggy*");

perhaps eventually this method will become private/hidden, and
bioperl-db API users will simply do this:

  ($id, $residues) = 
     $bioquery_resolver->do(q[FETCH Seq.primary_seq.display_id, 
                                    Seq.primary_seq.seq 
                              FROM Seq 
                              WHERE Seq.species.ncbi_taxa_id=7227]);



=cut

sub fetch_by_query {
    my ($self,$query) = @_;
    $query = $self->_get_bioquery($query);
    
    my $select_list = $query->{"select_list"};
    my $sqlq = 
      Bio::DB::SQL::SqlQuery->new;
    
    $sqlq->flag("distinct", 1);
    $sqlq->datacollections(qw(bioentry biodatabase));
    $sqlq->selectelts("bioentry.bioentry_id");
    
    $self->resolve_query($query, $sqlq, "biodatabase.biodatabase_id = bioentry.biodatabase_id");
    my $sth = $self->do_query($sqlq);
    
    my $rows = $sth->fetchall_arrayref;
    my @ids = map {$_->[0]} @$rows;
    my @seqs = 
	map {
	    print "ID=$_\n";
	    $self->fetch_by_dbID($_);
	} @ids;	
    return @seqs;
}

# this provides a hash of constraint name to resolution method;
# is this too perl "guts"y? don't want to put people off
# adding their own constraints.

# Mapping to subroutines does allow us
# some runtime introspection which is nice

# this does contain lots of repetitive code;
# it would be easy to make the adaptor even cleverer
# but that may be sacrificing too much clarity?

# the constraints are all very liberal in the values they
# accept; eg you can give a species name, an ncbi taxa id, a
# species object to the species constraint.
# this adds more code/complexity here but its nice for
# the API user
sub constraint_resolver {
    my $self = shift;
    return
    {"species"   => 
	 sub {
	     my ($self, $sqlq, $cvalue) = @_;		
	     my @wh = ();
	     my $dbh = $self->db->_db_handle;

	     my $speciesid;
	     my $species;
	     my $common_name;
	     if (!ref($cvalue)) {
		 if (int($cvalue)) {   # allow speciesid
		     $speciesid = int($cvalue);
		 }
		 else {
		     $common_name = $cvalue;
		     # assume that the common name was passed
		 }
	     }
	     else {
		 # we most likely have a species object here...
		 $species = $cvalue;
		 $common_name = $species->common_name;
		 $speciesid = $species->id;
	     }
	     if ($speciesid) {
		 push(@wh, "bioentry_taxa.taxa_id = $speciesid");
	     }
	     else {
		 push(@wh, 
		      "bioentry_taxa.taxa_id = taxa.taxa_id");
		 $sqlq->add_datacollection("taxa");
		 if ($common_name  =~ /\*/) {
		     $common_name  =~ s/\*/\%/g;
		     $common_name = $dbh->quote($common_name);
		     push(@wh, "taxa.common_name like $common_name");
		 }
		 else {
		     push(@wh, "taxa.common_name = ".$dbh->quote($common_name));
		 }
	     }
	     $sqlq->add_datacollection("bioentry_taxa");

	     push(@wh, "bioentry_taxa.bioentry_id = bioentry.bioentry_id");
	     return @wh;
	 },

    "references"    =>
    sub {
	my ($self, $sqlq, $cvalue) = @_;		
	my @wh = ();
	my $dbh = $self->db->_db_handle;
	$sqlq->add_datacollection("bioentry_reference");
	$sqlq->add_datacollection("reference");
	push(@wh, "bioentry_reference.bioentry_id = bioentry.bioentry_id");
	push(@wh, "bioentry_reference.reference_id = reference.reference_id");
	if ($cvalue  =~ /\*/) {
	    $cvalue  =~ s/\*/\%/g;
	    push(@wh, "reference.reference_title like ".$dbh->quote($cvalue));
	}
	else {
	    push(@wh, "reference.reference_title = ".$dbh->quote($cvalue));
	}
	return @wh;
    },

    "description"    =>
    sub {
	my ($self, $sqlq, $cvalue) = @_;		
	my @wh = ();
	my $dbh = $self->db->_db_handle;
	$sqlq->add_datacollection("bioentry_description");
	push(@wh, "bioentry_description.bioentry_id = bioentry.bioentry_id");
	if ($cvalue  =~ /\*/) {
	    $cvalue  =~ s/\*/\%/g;
	    push(@wh, "bioentry_description.description like ".$dbh->quote($cvalue));
	}
	else {
	    push(@wh, "bioentry_description.description = ".$dbh->quote($cvalue));
	}
	return @wh;
    },

    "keywords"    =>
    sub {
	my ($self, $sqlq, $cvalue) = @_;		
	my @wh = ();
	my $dbh = $self->db->_db_handle;
	$sqlq->add_datacollection("bioentry_keywords");
	push(@wh, "bioentry_keywords.bioentry_id = bioentry.bioentry_id");
	if ($cvalue  =~ /\*/) {
	    $cvalue  =~ s/\*/\%/g;
	    push(@wh, "bioentry_keywords.keywords like ".$dbh->quote($cvalue));
	}
	else {
	    push(@wh, "bioentry_keywords.keywords = ".$dbh->quote($cvalue));
	}
	return @wh;
    },

};
}


=head2 store

 Title   : store
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub store{
   my ($self,$dbid,$seq) = @_;

   if( !defined $seq || !ref $seq || !$seq->isa("Bio::SeqI") ) {
       $self->throw("$seq is not a Bio::SeqI!");
   }

   # simple store at the moment - 
   my $did       = $seq->id;
   my $accession = $seq->accession;
   my $version   = $seq->seq_version;
   my $division = 'UNK';

   
   if ( $seq->isa('Bio::Seq::RichSeqI')  && defined $seq->division) {
       $division  = $seq->division;
   }
   if( !defined $version ) {
       $version = 0;
   }

   if( !defined $did || !defined $accession ) {
       $self->throw("no display id ($did) or no accession ($accession). Cannot process");
   }

   my $sth = $self->prepare("insert into bioentry (biodatabase_id,bioentry_id,display_id,accession,entry_version,division) values ($dbid,NULL,'$did','$accession',$version,'$division')");
   $sth->execute;
      
   my $id = $sth->{'mysql_insertid'};

   $self->db->get_PrimarySeqAdaptor->store($id,$seq->primary_seq);

   my $desc = $seq->desc;
   $desc =~ s/\'/\\\'/g;
   if( defined $seq->desc && $seq->desc ne '' ) {
       $sth = $self->prepare("insert into bioentry_description (bioentry_id,description) VALUES ($id,'$desc')");
       $sth->execute;
   }

   if( $seq->isa('Bio::Seq::RichSeqI') ) {
       foreach my $date ($seq->get_dates) {
	   $sth = $self->prepare("insert into bioentry_date (bioentry_id,date) VALUES ($id,'$date')");
	   $sth->execute;
       }
       if (my $kw = $seq->keywords) {
	   $sth= $self->prepare("insert into bioentry_keywords(bioentry_id,keywords) VALUES ($id,'$kw')");
	   $sth->execute;
       }
   }


   my $species = $seq->species;

   if( defined $species ) {
       my $species_id = $self->db->get_SpeciesAdaptor->store_if_needed($species);
       $sth = $self->prepare("insert into bioentry_taxa (bioentry_id,taxa_id) VALUES ($id,$species_id)");
       $sth->execute;
   }   

   my $rank = 1;
   my $adp  = $self->db->get_SeqFeatureAdaptor();

   foreach my $sf ( $seq->top_SeqFeatures ) {
       $adp->store($sf,$rank,$id);
       $rank++; 
   }

   $rank = 1;
   $adp = $self->db->get_CommentAdaptor();
   foreach my $comment ( $seq->annotation->each_Comment ) {
       $adp->store($comment,$rank,$id);
       $rank++;
   }
   
   $rank = 1;
   my $rdp = $self->db->get_ReferenceAdaptor();
   foreach my $ref ( $seq->annotation->each_Reference ) {
       my $rid = $rdp->store_if_needed($ref);

       my $start='NULL';
       my $end='NULL';
       if ($ref->start) {
	   $start=$ref->start;
       }
       if ($ref->end) {
	   $end=$ref->end;
       }
       $sth = $self->prepare("insert into bioentry_reference(bioentry_id,reference_id,reference_start,reference_end,reference_rank) values($id,$rid,$start,$end,$rank)");
       #print STDERR "insert into bioentry_reference(bioentry_id,reference_id,reference_rank) values($id,$rid,$rank)\n";
       $sth->execute;
       $rank++;
   }


   $adp = $self->db->get_DBLinkAdaptor();
   foreach my $dblink ( $seq->annotation->each_DBLink ) {
       $adp->store($dblink,$id);
   }

   
   return $id;

}


=head2 remove_by_dbID 

 Title   : remove
 Usage   : $seq_adaptor->remove_by_dbID($db_id) or $seq_adaptor->remove_by_dbID(@db_ids)
 Function: removes sequence(s) by their database IDs
 Example :
 Returns : 
 Args    :


=cut

sub remove_by_dbID {
	my ($self) = shift;
	
	my ($be) = join ",", @_; 
	
	$self->throw("Required parameter sequence dbID is missing") unless $be;  

	$self->db->get_SeqFeatureAdaptor->remove_by_bioentry_id(@_); 
	$self->db->get_DBLinkAdaptor->remove_by_bioentry_id(@_); 
	$self->db->get_ReferenceAdaptor->remove_by_bioentry_id(@_); 	
	

# Simple Job - removing records from tables that are not linked to anything else	
	
	my @simple_tables = qw( bioentry                   
						 bioentry_date              
						 bioentry_description       						       
						 bioentry_keywords          
						 bioentry_taxa              
						 biosequence                
						 comment);

	foreach my $tab (@simple_tables)  {
		my $sth = $self->prepare("DELETE FROM $tab WHERE bioentry_id IN($be)");
		$sth->execute(); 
	}

	
}

sub remove_by_db_and_accession {
   my ($self,$db,$accession) = @_;

   my $sth = $self->prepare("select en.bioentry_id from bioentry en, biodatabase biodb where biodb.name = '$db' AND en.biodatabase_id = biodb.biodatabase_id AND en.accession = '$accession'");
   $sth->execute;

   my ($enid) = $sth->fetchrow_array();

   if( defined $enid ) {
       $self->remove_by_dbID($enid); 
   } else {
       $self->throw("Unable to retrieve sequence with $db and $accession");
   }
   
}


=head2 get_dates

 Title   : get_dates
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub get_dates{
    my ($self,$bioentry_id) = @_;
    
    my $sth = $self->prepare("select date from bioentry_date where bioentry_id = $bioentry_id");
    $sth->execute();
    my @dates;
    my $seen=0;
    while (my ($date) = $sth->fetchrow_array()) {
	push (@dates,$date);
	$seen=1;
    }
    $seen || return undef;
    return @dates;
}

=head2 get_taxa_id

 Title   : get_taxa_id
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub get_taxa_id{
   my ($self,$bioentry_id) = @_;

   my $sth = $self->prepare("select taxa_id from bioentry_taxa where bioentry_id = $bioentry_id");
   $sth->execute();

   my ($taxa) = $sth->fetchrow_array();
   return $taxa;
}

=head2 get_keywords

 Title   : get_keywords
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub get_keywords{
   my ($self,$id) = @_;

   my $sth = $self->prepare("select keywords from bioentry_keywords where bioentry_id = $id");
   $sth->execute;

   my ($desc) = $sth->fetchrow_array;

   return $desc;
}
