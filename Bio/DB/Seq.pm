

#
# BioPerl module for Bio::DB::Seq
#
# Cared for by Ewan Birney <birney@ebi.ac.uk>
#
# Copyright Ewan Birney
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::DB::Seq - DESCRIPTION of Object

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


package Bio::DB::Seq;
use vars qw(@ISA);
use strict;

# Object preamble - inherits from Bio::Root::RootI

use Bio::Root::RootI;
use Bio::SeqI;
use Bio::DB::Annotation;

@ISA = qw(Bio::Root::RootI Bio::SeqI);
# new() can be inherited from Bio::Root::RootI


sub new {
    my ($class,@args) = @_;

    my $self = {};
    bless $self,$class;

    my($primary_id,$display_id,$accession,$version,$adaptor,$length,$division,$desc) = 
	$self->_rearrange([qw(PRIMARY_ID DISPLAY_ID ACCESSION VERSION ADAPTOR LENGTH DIVISION DESC)],@args);

    if( !defined $primary_id || !defined $display_id || !defined $accession || !defined $adaptor || !defined $length) {
	$self->throw("Not got one of the arguments in DB::Seq new [$primary_id,$display_id,$accession,$adaptor,$length]");
    }

    $self->primary_id($primary_id);
    $self->display_id($display_id);
    $self->accession($accession);
    $self->version($version);
    $self->adaptor($adaptor);
    $self->length($length);
    $self->division($division);
    $self->desc($desc);    
    return $self;
}


=head2 primary_seq

 Title   : primary_seq
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub primary_seq{
   my ($self,@args) = @_;

   if( !defined $self->{'_primary_seq'} ) {
       $self->{'_primary_seq'} = $self->adaptor->db->get_PrimarySeqAdaptor->fetch_by_dbID($self->primary_id);
   } 

   return $self->{'_primary_seq'};
}


=head2 seq

 Title   : seq
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub seq{
   my ($self,@args) = @_;

   return $self->primary_seq->seq;
}

=head2 subseq

 Title   : subseq
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub subseq{
   my ($self,$start,$end) = @_;

   return $self->primary_seq->subseq($start,$end);
}

=head2 moltype

 Title   : moltype
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub moltype{
   my ($self,@args) = @_;

   return $self->primary_seq->moltype;
}



=head2 desc

 Title   : desc
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub desc{
   my $self = shift;

   if (@_) {
	my $value = shift;
	$self->{'desc'} = $value;
}
		

   return $self->{'desc'};
}


=head2 annotation

 Title   : annotation
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub annotation{
   my ($self,@args) = @_;

   if( !defined $self->{'_annotation'} ) {
       $self->{'_annotation'} = Bio::DB::Annotation->new( -adaptor => $self->adaptor->db,
							  -bioentry_id => $self->primary_id);
   }

   return $self->{'_annotation'};

}

=head2 division

 Title   : division
 Usage   : $obj->division($newval)
 Function: Getset for division value
 Returns : value of division
 Args    : newvalue (optional)


=cut

sub division{
   my $obj = shift;
   if( @_ ) {
      my $value = shift;
      $obj->{'division'} = $value;
    }
    return $obj->{'division'};

}

=head2 get_dates

 Title   : get_dates
 Usage   : $obj->get_dates($newval)
 Function: Getset for get_dates value
 Returns : value of get_dates
 Args    : newvalue (optional)


=cut

sub get_dates{
    my ($self,@args)=@_;
    
    if( !defined $self->{'_date_array'} ) {
	my @dates = $self->adaptor->get_dates($self->primary_id);
	if( @dates ) {
	    $self->{'_date_array'}=\@dates;
	} else {
	    return undef;
	}
    }
    return @{$self->{'_date_array'}};
}


=head2 species

 Title   : species
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub species{
   my ($self,@args) = @_;

   if( !defined $self->{'_species'} ) {
       my $taxa = $self->adaptor->get_taxa_id($self->primary_id);
       if( defined $taxa ) {
	   $self->{'_species'} = $self->adaptor->db->get_SpeciesAdaptor->fetch_by_dbID($taxa);
       } else {
           $self->{'_species'} = undef;
       }
   }

   return $self->{'_species'};

}

=head2 top_SeqFeatures

 Title   : top_SeqFeatures
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub top_SeqFeatures{
   my ($self,@args) = @_;

   my @array;
   if( !defined $self->{'_seqfeature_array'} ) {
       @array = $self->adaptor->db->get_SeqFeatureAdaptor->fetch_by_bioentry_id($self->primary_id);
       my $accsv=$self->accession.".".$self->version;
       foreach my $sf (@array) {
	   $sf->location->seq_id($accsv);
       }
       $self->{'_seqfeature_array'} = \@array;
   }
   
   return @{$self->{'_seqfeature_array'}};
}

=head2 all_SeqFeatures

 Title   : all_SeqFeatures
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub all_SeqFeatures{
   my ($self,@args) = @_;

   $self->warn("Features not implemented yet in Bio::DB::Seq");

   return ();
}



=head1 Stored id/values

=head2 primary_id

 Title   : primary_id
 Usage   : $obj->primary_id($newval)
 Function: 
 Example : 
 Returns : value of primary_id
 Args    : newvalue (optional)


=cut

sub primary_id{
   my ($obj,$value) = @_;
   if( defined $value) {
      $obj->{'primary_id'} = $value;
    }
    return $obj->{'primary_id'};

}

=head2 display_id

 Title   : display_id
 Usage   : $obj->display_id($newval)
 Function: 
 Example : 
 Returns : value of display_id
 Args    : newvalue (optional)


=cut

sub display_id{
   my ($obj,$value) = @_;
   if( defined $value) {
      $obj->{'display_id'} = $value;
    }
    return $obj->{'display_id'};

}

sub accession_number {
    my $self = shift;
    return $self->accession;
}

=head2 accession

 Title   : accession
 Usage   : $obj->accession($newval)
 Function: 
 Example : 
 Returns : value of accession
 Args    : newvalue (optional)


=cut

sub accession{
   my ($obj,$value) = @_;
   if( defined $value) {
      $obj->{'accession'} = $value;
    }
    return $obj->{'accession'};

}

=head2 version

 Title   : version
 Usage   : $obj->version($newval)
 Function: Getset for version value
 Returns : value of version
 Args    : newvalue (optional)


=cut

sub version{
   my $obj = shift;
   if( @_ ) {
      my $value = shift;
      $obj->{'version'} = $value;
    }
    return $obj->{'version'};

}

=head2 seq_version

 Title   : seq_version
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub seq_version{
   my ($self,@args) = @_;

   #This creates the SV line in EMBL/Genbank
   my $string = $self->accession.".".$self->version;
   return $string;

}


=head2 adaptor

 Title   : adaptor
 Usage   : $obj->adaptor($newval)
 Function: 
 Example : 
 Returns : value of adaptor
 Args    : newvalue (optional)


=cut

sub adaptor{
   my ($obj,$value) = @_;
   if( defined $value) {
      $obj->{'adaptor'} = $value;
    }
    return $obj->{'adaptor'};

}


=head2 keywords

 Title   : keywords
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub keywords{
   my ($self,@args) = @_;

   if( defined $self->{'_keywords_cache'} ) {
       return $self->{'_keywords_cache'};
   }

   my $d = $self->adaptor->get_keywords($self->primary_id);

   if( !defined $d ) { $d = ""; }

   $self->{'_keywords_cache'} = $d;

   return $d;
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
      $obj->{'length'} = $value;
    }
    return $obj->{'length'};

}

sub DESTROY {
    #print STDERR "Releasing seq object\n!";
}






