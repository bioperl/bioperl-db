# $Id$

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

   my $sth = $self->prepare("select en.display_id,en.accession,en.entry_version,bs.molecule,en.division from bioentry en,biosequence bs where bs.bioentry_id = en.bioentry_id and bs.bioentry_id = $id");

   $sth->execute;

   my ($display,$acc,$version,$mol,$div) = $sth->fetchrow_array;

   if( !defined $display ) {
       $self->throw("Bioentry id $id does not have a biosequence or bioentry ");
   }

   my $seq = Bio::DB::Seq->new( '-primary_id' => $id,
                                '-display_id' => $display,
                                '-accession'  => $acc,
                                '-version'    => $version,
                                '-alphabet'   => $mol,
                                '-division'   => $div,
                                '-adaptor'    => $self);
   my $DESC_ID =
     $self->db->get_OntologyTermAdaptor->DESCRIPTION_ID;
   my $desc =
     $self->select_colval(["bioentry_qualifier_value"],
                          ["bioentry_id = $id",
                           "ontology_term_id = $DESC_ID"],
                          "qualifier_value");
   $seq->desc($desc);
   return $seq;
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
        my $DESC_ID =
          $self->db->get_OntologyTermAdaptor->DESCRIPTION_ID;
	$sqlq->add_datacollection("bioentry_qualifier_value");
	push(@wh, "bioentry_qualifier_value.bioentry_id = bioentry.bioentry_id");
	push(@wh, "bioentry_qualifier_value.ontology_term_id = $DESC_ID");
	if ($cvalue  =~ /\*/) {
	    $cvalue  =~ s/\*/\%/g;
	    push(@wh, "bioentry_qualifier_value.qualifier_value like ".$dbh->quote($cvalue));
	}
	else {
	    push(@wh, "bioentry_qualifier_value.qualifier_value = ".$dbh->quote($cvalue));
	}
	return @wh;
    },

    "keywords"    =>
    sub {
	my ($self, $sqlq, $cvalue) = @_;		
	my @wh = ();
	my $dbh = $self->db->_db_handle;
        my $DESC_ID =
          $self->db->get_OntologyTermAdaptor->KEYWORDS_ID;
	$sqlq->add_datacollection("bioentry_qualifier_value");
	push(@wh, "bioentry_qualifier_value.bioentry_id = bioentry.bioentry_id");
	push(@wh, "bioentry_qualifier_value.ontology_term_id = $DESC_ID");
	if ($cvalue  =~ /\*/) {
	    $cvalue  =~ s/\*/\%/g;
	    push(@wh, "bioentry_qualifier_value.qualifier_value like ".$dbh->quote($cvalue));
	}
	else {
	    push(@wh, "bioentry_qualifier_value.qualifier_value = ".$dbh->quote($cvalue));
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
   
   my $version; 
   
   if ($seq->isa("Bio::DB::Seq")) {
   	   $version = $seq->version;
   }
   else {
   	   $version = $seq->seq_version; 
   }
   
   
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

       my $sth;
       my $uniqueh =
         {biodatabase_id=>$dbid,
          accession=>$accession,
          entry_version=>$version,
#          division=>$division,
         };
       # enforce this constraint:UNIQUE (biodatabase_id,accession,entry_version,division)
       my $id = $self->select_colval("bioentry",
                                     $uniqueh,
                                     "bioentry_id");

       # NOTE:
       # what are the semantics of the store() method?
       # if the entry already exists, should we
       # update or should we delete and add a new one?
       # the former may be useful, but could be
       # dangerous with MySQL
       my $STORE_SEMANTICS = "replace";
       if ($id && $STORE_SEMANTICS eq "replace") {
           $self->remove_by_dbID($id);
           $id = undef;
       }
       if (!$id) {
           $sth = $self->prepare("insert into bioentry (biodatabase_id,display_id,accession,entry_version,division) values ($dbid,'$did','$accession',$version,'$division')");
           $sth->execute;
           $id = $self->get_last_id("bioentry");
       }

       $self->db->get_PrimarySeqAdaptor->store($id,$seq->primary_seq);

       if ( defined $seq->desc && $seq->desc ne '' ) {
           my $TERM_ID =
             $self->db->get_OntologyTermAdaptor->DESCRIPTION_ID;
           $self->insert("bioentry_qualifier_value",
                         {bioentry_id=>$id,
                          qualifier_value=>$seq->desc,
                          ontology_term_id=>$TERM_ID});
       }

       if ( $seq->isa('Bio::Seq::RichSeqI') ) {
           my $TERM_ID =
             $self->db->get_OntologyTermAdaptor->DATES_ID;
           foreach my $date ($seq->get_dates) {
               $self->insert("bioentry_qualifier_value",
                             {bioentry_id=>$id,
                              qualifier_value=>$date,
                              ontology_term_id=>$TERM_ID});
           }
           if (my $kw = $seq->keywords) {
               my $TERM_ID =
                 $self->db->get_OntologyTermAdaptor->KEYWORDS_ID;
               $self->insert("bioentry_qualifier_value",
                             {bioentry_id=>$id,
                              qualifier_value=>$kw,
                              ontology_term_id=>$TERM_ID});
           }
       }


       my $species = $seq->species;

       if ( defined $species ) {
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

       foreach my $comment ( $seq->annotation->get_Annotations('comment') ) {
           $adp->store($comment,$rank,$id);
           $rank++;
       }
		
       $rank = 1;
       my $rdp = $self->db->get_ReferenceAdaptor();
       foreach my $ref ( $seq->annotation->get_Annotations('reference') ) {
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
       foreach my $dblink ( $seq->annotation->get_Annotations('dblink') ) {
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
	
	my @simple_tables = qw( 
                               bioentry_qualifier_value
                               bioentry_taxa              
                               biosequence                
                               comment
                               bioentry                   
                              );
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
    
    my $TERM_ID =
      $self->db->get_OntologyTermAdaptor->DATES_ID;

    my $sth = $self->prepare("select qualifier_value from bioentry_qualifier_value where bioentry_id = $bioentry_id and ontology_term_id = $TERM_ID");
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


=head2 get_length

 Title   : get_length
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub get_length{
   my ($self,$id) = @_;

   my $sth = $self->prepare("select length(bs.biosequence_str) from bioentry en,biosequence bs where bs.bioentry_id = en.bioentry_id and en.bioentry_id = $id");
   $sth->execute();

   my ($length) = $sth->fetchrow_array();

   return $length;
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
   my $TERM_ID =
     $self->db->get_OntologyTermAdaptor->KEYWORDS_ID;

   my $sth = $self->prepare("select qualifier_value from bioentry_qualifier_value where bioentry_id = $id and ontology_term_id = $TERM_ID");
   $sth->execute;

   my ($kw) = $sth->fetchrow_array;

   return $kw;
}

=head2 get_description_by_accession

 Title   : get_description_by_accession
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub get_description_by_accession{
   my ($self,$acc) = @_;

   my $TERM_ID =
     $self->db->get_OntologyTermAdaptor->DESCRIPTION_ID;
   my $sth = $self->prepare("select qualifier_value from bioentry_qualifier_value qv, bioentry e where accession = '$acc' and e.bioentry_id = qv.bioentry_id");
   $sth->execute;

   my ($desc) = $sth->fetchrow_array;

   return $desc;
}


=head2 get_all_available

 Title   : get_all_available
 Usage   : $SeqAd->get_all_available($molecule_type, $dbname)
 Function:  to retrieve the names of all sequences of $type
 Example :  $SeqAd->get_all_available("dna");
 Returns : list of scalars; all valid sequence names
 Args    : biosequence.molecule (e.g. 'dna'), biodatabase.name (eg "EMBL_Mouse_Contigs")


=cut


sub get_all_available {
	my ($self, $type, $dbname) = @_;
	my $query = "SELECT be.accession ".
		"FROM bioentry be, ".
		"biodatabase bd, ".
		"biosequence bs ".
		"WHERE be.bioentry_id = bs.bioentry_id ".
		"AND be.biodatabase_id = bd.biodatabase_id ".
		"AND bd.name = '$dbname' ";
	if ($type){$query .= "AND bs.molecule = '$type'"};
 
	my $sth = $self->prepare($query);
	$sth->execute();
	my @available;
	while (my ($seqname) = $sth->fetchrow_array){
		push @available, $seqname;
	}
	return @available;	
}



=head2 get_seq_lengths

 Title   : get_seq_lengths
 Usage   : $SeqAd->get_seq_lengths(@seqnames)
 Function: retrieve lenghts of all/selected sequences
 Example : $SeqAd->get_seq_lengths("At15GH6", "ABC44S");
 Returns : hashref of {seqname} = length for any valid names
 Args    : optional list of desired sequences, returns all by default


=cut

sub get_seq_lengths {
	my ($self, @seqs) = @_;
	my $query = "select be.accession, length(bs.biosequence_str) ".
		"from bioentry be, ".
		"biosequence bs ".
		"where be.bioentry_id = bs.bioentry_id ";
	if ($seqs[0]){
		my $seqlist = join ",", map {qq("$_")} @seqs;
		#print "\nSEQLIST $seqlist\n";
		$query .= "and be.accession in ($seqlist)"
	}

	my $sth = $self->prepare($query);
	$sth->execute();
	
	my %result;
	while (my ($id, $length) = $sth->fetchrow_array){
		$result{$id} = $length;
	}
	return \%result;
}



1;
