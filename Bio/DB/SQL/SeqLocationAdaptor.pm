
#
# BioPerl module for Bio::DB::SQL::SeqLocationAdaptor
#
# Cared for by Ewan Birney <birney@ebi.ac.uk>
#
# Copyright Ewan Birney
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::DB::SQL::SeqLocationAdaptor - An adaptor for retrieving sequence locations for a db.

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


package Bio::DB::SQL::SeqLocationAdaptor;
use vars qw(@ISA);
use strict;

# Object preamble - inherits from Bio::Root::RootI

use Bio::DB::SQL::BaseAdaptor;

use Bio::Location::Split;
use Bio::Location::Fuzzy;
use Bio::Location::Simple;

@ISA = qw(Bio::DB::SQL::BaseAdaptor);

sub _table {"seqfeature_location"}

# new() can be inherited from Bio::Root::RootI


=head2 fetch_by_dbIDs

 Title   : fetch_by_dbIDs
 Usage   :
 Function:
 Example :
 Returns : hashref of locations by dbid
 Args    :

=cut

# WARNING this does not handle remote locations yet at all...
sub fetch_by_dbIDs {
   my ($self,$idarrayref) = @_;

   my $loc_by_sf = {};
   # accept scalars
   my @ids = ref($idarrayref) ? @$idarrayref : ($idarrayref);
   my $idjoin = join(",", @ids);
   my @array;

   my @rows =
     $self->selectall("seqfeature_location",
                      "seqfeature_id in ($idjoin)");
   my @locids = map {$_->{seqfeature_location_id}} @rows;
   my $locidjoin = join(",", @locids);
   my @qualrows =
     $self->selectall("location_qualifier_value lqv, ontology_term t",
                      ["seqfeature_location_id in ($locidjoin)",
                       "lqv.ontology_term_id = t.ontology_term_id"]);
   my @remoterows =
     $self->selectall("remote_seqfeature_name",
                      "seqfeature_location_id in ($locidjoin)");
   my $count = 0;
   my $component;
   foreach my $hr (@rows) {
       my ($sfid,$sflocid,$seq_start,$seq_end,$seq_strand) =
         map {
             $hr->{$_}
         } qw(seqfeature_id
              seqfeature_location_id
              seq_start
              seq_end
              seq_strand);
       # hmm, should really be a factory here
       my $loc_class = "Bio::Location::Simple";
       $component = $loc_class->new();
       $component->start($seq_start);
       $component->end($seq_end);
       $component->strand($seq_strand);
       if (!$loc_by_sf->{$sfid}) {
           $loc_by_sf->{$sfid} = [];
       }
       # REMOTE FEATURES

       # could be made faster....
       my @remote = grep { $_->{seqfeature_location_id} == $sflocid } @remoterows;
       if (@remote) {
           my $r = shift @remote;
           if (@remote) {
               $self->throw(">1 remote loc for $sflocid");
           }
           my $acc = $r->{accession};
           my $v = $r->{version};
	   my $accsv=$acc.".".$v;
	   $component->is_remote(1);
	   $component->seq_id($accsv);
       }

       # FUZZY/QUALIFIED FEATURES

       # could be made faster....
       my @qual = grep { $_->{seqfeature_location_id} == $sflocid } @qualrows;
       if (@qual) {
           $loc_class = "Bio::Location::Fuzzy";
           $component = $loc_class->new();
           $component->start($seq_start);
           $component->end($seq_end);
           $component->min_end(undef);
           $component->max_end(undef);
           $component->min_start(undef);
           $component->max_start(undef);
           $component->strand($seq_strand);
           foreach my $q (@qual) {
               my $n =$q->{term_name};
               if ($component->can($n)) {
                   $component->$n($q->{qualifier_value});
               }
               else {
                   $self->throw("unapplicable qualifier $n for $sflocid");
               }
           }
       }
       push(@{$loc_by_sf->{$sfid}}, $component);
   }

   # now make the location objs for the hash
   foreach my $sfid (@ids) {
       my $locs = $loc_by_sf->{$sfid};
       if( !$locs || !@$locs) {
           $self->throw("no location for $sfid");
       }
       if (scalar(@$locs) == 1) {
           $loc_by_sf->{$sfid} = pop @$locs;
       }
       else {
           my $out = Bio::Location::Split->new();

           foreach my $loc ( @$locs ) {
               $out->add_sub_Location($loc);
           }
           $loc_by_sf->{$sfid} = $out;
       }
   }

   return $loc_by_sf;
}

=head2 fetch_by_dbID

 Title   : fetch_by_dbID
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub fetch_by_dbID{
   my ($self,$dbid) = @_;

   my $h = $self->fetch_by_dbIDs($dbid);
   my @keys = keys %$h;
   my $k = shift @keys;
   $self->throw("no loc for $dbid") unless $h;
   $self->throw("assertion error $dbid") if @keys;
   $self->throw("assertion error $dbid") if $k != $dbid;
   my $out = $h->{$k};
   $self->throw("assertion error $dbid") unless $out;
   return $out;
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
   my ($self,$location,$seqfeature_id) = @_;

   if( !defined $seqfeature_id ) {
       $self->throw("no seqfeature_id  ...");
   }
   if( $location->isa('Bio::Location::SplitLocationI')  ) {
       my $rank = 1;
       foreach my $sub ( $location->sub_Location ) {
	   $self->_store_component($sub,$seqfeature_id,$rank);
	   $rank++;
       }
   } elsif( $location->isa('Bio::Location::Simple') ) {
       $self->_store_component($location,$seqfeature_id,1);
   } elsif( $location->isa('Bio::Location::FuzzyLocationI') ) {
       $self->_store_component($location,$seqfeature_id,1);
   } else {
       $self->throw("Not a simple location nor a split. Yikes");
   }

       
}

=head2 _store_component

 Title   : _store_component
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut


sub _nextid {
	my ($self) = @_;
	unless ($self->{_nextid}){$self->{_nextid} = 0}
	return ++$self->{_nextid};
}

sub _store_component{
   my ($self,$location,$seqfeature_id,$rank) = @_;

   if( !defined $location ) {
       $self->throw("Have to store with a location");
   }

   if( !defined $rank ) {
       $self->throw("Have to store with a rank");
   }
   my $start  = $location->start;
   my $end    = $location->end;
   my $strand = $location->strand;

   $start = 'NULL' unless defined $start;
   $end =   'NULL' unless defined $end;

   #print STDERR "Got $seqfeature_id $start $end $strand with $location\n";

       my $sth = $self->prepare("insert into seqfeature_location (seqfeature_id,seq_start,seq_end,seq_strand,location_rank) VALUES ($seqfeature_id,$start,$end,$strand,$rank)");
       $sth->execute;
       my $id= $self->get_last_id;

       if( $location->isa('Bio::Location::FuzzyLocationI')  ) {
           $self->_store_qual($id, "max_start", $location->max_start);
           $self->_store_qual($id, "min_start", $location->min_start);
           $self->_store_qual($id, "max_end", $location->max_end);
           $self->_store_qual($id, "min_end", $location->min_end);
           $self->_store_qual($id, "end_pos_type", $location->end_pos_type);
           $self->_store_qual($id, "start_pos_type", $location->start_pos_type);
           $self->_store_qual($id, "location_type", $location->location_type);
       }
       #$location->seq_id =~ /(\S+)\.(\S+)/;
       my $acc = $1;
       my $v = $2;
       if ($location->is_remote) {
           #       my $sth = $self->prepare("insert into remote_seqfeature_name (seqfeature_location_id,accession,version) values($id,'$acc',$v)");
           #       $sth->execute;
       }
       return $id;
}

sub _store_qual {
    my $self = shift;
    my ($loc_id, $qual, $slot) = @_;
    return unless defined $slot;
    # get the qualifier from the controlled vocab
    my $qual_id = $self->db->get_OntologyTermAdaptor->get_id($qual);

    #This silly code is just to avoid warnings when trying to int a string
    #There must be a better way to check if a scalar is numeric???
    my $intslot=$slot;    
    $intslot =~ s/E|e|\+|\-//;
    if($intslot =~ /^\d+$/)    {
	$intslot = int($slot);
    }
    else {
	$intslot = 0;
    }

    $self->insert_nopk("location_qualifier_value",
                  {ontology_term_id=>$qual_id,
                   seqfeature_location_id=>$loc_id,
                   qualifier_value=>$slot,
                   qualifier_int_value=>$intslot});
}

=head2 remove_by_dbID

 Title   : remove_by_dbID
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub remove_by_dbID{
   	my ($self) = shift;
	
	my ($dbID) = join (",",@_); 
	return unless $dbID;
        my $loc_ids =
          join(", ",
               $self->select_colvals("seqfeature_location",
                                     "seqfeature_id in ($dbID)",
                                     "seqfeature_location_id")
              );
        my $sth;
        if ($loc_ids) {
            $sth = $self->prepare("DELETE FROM location_qualifier_value WHERE seqfeature_location_id IN($loc_ids)");
            $sth->execute();
        }
	$sth = $self->prepare("DELETE FROM seqfeature_location WHERE seqfeature_id IN($dbID)");
	$sth->execute();
	
	$self->_clean_orphans(); 
	return $sth->rows; 
}


=head2 _clean_orphans

 Title   : _clean_orphans
 Usage   : 
 Function: Checks the remote_seqfeature_name table for entries that are not linked to any record in seqfeature_location and deletes such entries. 
 Example :
 Returns : number of records deleted
 Args    : none


=cut

sub _clean_orphans {

	my($self) = shift; 

	my $sth = $self->prepare(
			"select remote_seqfeature_name.seqfeature_location_id from remote_seqfeature_name ".
			"left join seqfeature_location on ".
			"remote_seqfeature_name.seqfeature_location_id  = seqfeature_location.seqfeature_location_id  where ".
			"seqfeature_location.seqfeature_location_id is NULL" )	;
	
	
	$sth->execute(); 
	
	
	my $orph = $sth->fetchrow_array(); 	
	return 0 if not $orph; 

	while (my $a = $sth->fetchrow_array()) {
		$orph = $orph.",".$a; 		
	}
	
	$sth = $self->prepare("DELETE FROM remote_seqfeature_name WHERE seqfeature_location_id IN($orph)"); 
	$sth->execute;
		
	return $sth->rows;  
}

1; 
