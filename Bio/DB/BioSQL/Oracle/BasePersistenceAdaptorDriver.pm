# $Id$
#
# BioPerl module for Bio::DB::BioSQL::Oracle::BasePersistenceAdaptorDriver
#
# Cared for by Hilmar Lapp <hlapp at gmx.net>
#
# Copyright Hilmar Lapp
#
# You may distribute this module under the same terms as perl itself

#
# (c) Hilmar Lapp, hlapp at gmx.net, 2002.
# (c) GNF, Genomics Institute of the Novartis Research Foundation, 2002.
#
# You may distribute this module under the same terms as perl itself.
# Refer to the Perl Artistic License (see the license accompanying this
# software package, or see http://www.perl.com/language/misc/Artistic.html)
# for the terms under which you may use, modify, and redistribute this module.
# 
# THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
# MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#

# POD documentation - main docs before the code

=head1 NAME

Bio::DB::BioSQL::Oracle::BasePersistenceAdaptorDriver - DESCRIPTION of Object

=head1 SYNOPSIS

Give standard usage here

=head1 DESCRIPTION

Describe the object here

=head1 FEEDBACK

=head2 Mailing Lists

User feedback is an integral part of the evolution of this and other
Bioperl modules. Send your comments and suggestions preferably to
the Bioperl mailing list.  Your participation is much appreciated.

  bioperl-l@bioperl.org              - General discussion
  http://bioperl.org/MailList.shtml  - About the mailing lists

=head2 Reporting Bugs

Report bugs to the Bioperl bug tracking system to help us keep track
of the bugs and their resolution. Bug reports can be submitted via
email or the web:

  bioperl-bugs@bioperl.org
  http://bioperl.org/bioperl-bugs/

=head1 AUTHOR - Hilmar Lapp

Email hlapp at gmx.net

Describe contact details here

=head1 CONTRIBUTORS

Additional contributors names and emails here

=head1 APPENDIX

The rest of the documentation details each of the object methods.
Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::DB::BioSQL::Oracle::BasePersistenceAdaptorDriver;
use vars qw(@ISA);
use strict;
use Data::Dumper;

# Object preamble - inherits from Bio::Root::Root

use Bio::DB::BioSQL::BaseDriver;

@ISA = qw(Bio::DB::BioSQL::BaseDriver);

#
# here goes our entire object-relational mapping
#
my %object_entity_map = (
		"Bio::BioEntry"                    => "BS_bioentry",
		"Bio::PrimarySeqI"                 => "BS_bioentry",
		"Bio::DB::BioSQL::PrimarySeqAdaptor"
		                                   => "BS_bioentry",
		"Bio::SeqI"                        => "BS_bioentry",
		"Bio::DB::BioSQL::SeqAdaptor"      => "BS_bioentry",
		"Bio::IdentifiableI"               => "BS_bioentry",
		"Bio::ClusterI"                    => "BS_bioentry",
		"Bio::DB::BioSQL::ClusterAdaptor"  => "BS_bioentry",
		"Bio::DB::BioSQL::BiosequenceAdaptor"
		                                   => "BS_biosequence",
		"Bio::SeqFeatureI"                 => "BS_seqfeature",
		"Bio::DB::BioSQL::SeqFeatureAdaptor"
			                           => "BS_seqfeature",
		"Bio::Species"                     => "BS_taxon",
		"Bio::DB::BioSQL::SpeciesAdaptor"  => "BS_taxon",
		"Bio::LocationI"                   => "BS_seqfeature_location",
		"Bio::DB::BioSQL::LocationAdaptor" => "BS_seqfeature_location",
		"Bio::DB::BioSQL::BioNamespaceAdaptor"
                                                   => "BS_biodatabase",
		"Bio::DB::Persistent::BioNamespace"=> "BS_biodatabase",
		"Bio::Annotation::DBLink"          => "BS_dbxref",
		"Bio::DB::BioSQL::DBLinkAdaptor"   => "BS_dbxref",
		"Bio::Annotation::Comment"         => "BS_comment",
		"Bio::DB::BioSQL::CommentAdaptor"  => "BS_comment",
		"Bio::Annotation::Reference"       => "BS_reference",
		"Bio::DB::BioSQL::ReferenceAdaptor"=> "BS_reference",
		"Bio::Annotation::SimpleValue"     => "BS_ontology_term",
		"Bio::Annotation::OntologyTerm"    => "BS_ontology_term",
		"Bio::DB::BioSQL::SimpleValueAdaptor"
                                                   => "BS_ontology_term",
		"Bio::Ontology::TermI"             => "BS_ontology_term",
		"Bio::DB::BioSQL::TermAdaptor"     => "BS_ontology_term",
		   );
my %association_entity_map = (
	 "BS_bioentry" => {
	     "BS_dbxref"         => "BS_bioentry_dbxref_assoc",
	     "BS_reference"      => "BS_bioentry_ref_assoc",
	     "BS_ontology_term"  => "BS_bioentry_qualifier_assoc",
	     "BS_bioentry"       => {
		 "BS_ontology_term" => "BS_bioentry_assoc",
	     }
	 },
	 "BS_seqfeature" => {
	     "BS_ontology_term"  => "BS_seqfeature_qualifier_assoc",
	     "BS_dbxref"         => undef,
	     "BS_reference"      => undef,
	     "BS_seqfeature"     => {
		 "BS_ontology_term" => "BS_seqfeature_assoc",
	     }
	 },
	 "BS_dbxref"   => {
	     "BS_bioentry"       => "BS_bioentry_dbxref_assoc",
	     "BS_seqfeature"     => undef,
	 },
	 "BS_reference"   => {
	     "BS_bioentry"       => "BS_bioentry_ref_assoc",
	     "BS_seqfeature"     => undef,
	 },
	 "BS_ontology_term" => {
	     "BS_bioentry"       => "BS_bioentry_qualifier_assoc",
	     "BS_seqfeature"     => "BS_seqfeature_qualifier_assoc",
	 },
			       );
my %slot_attribute_map = (
	 "BS_biodatabase" => {
	     "namespace"      => "name",
	     "authority"      => "authority",
	 },
	 "BS_taxon" => {
	     "classification" => "full_lineage",
	     "common_name"    => "common_name",
	     "ncbi_taxid"     => "ncbi_taxon_id",
	     "binomial"       => "name",
	     "variant"        => "variant",
	 },
	 "BS_bioentry" => {
	     "display_id"     => "display_id",
	     "primary_id"     => "identifier",
	     "accession_number" => "accession",
	     "desc"           => "description",
	     "description"    => "description",
	     "version"        => "version",
	     "bionamespace"   => "db_oid",
	     "parent"         => "src_ent_oid",
	     "child"          => "tgt_ent_oid",
	 },
	 "BS_bioentry_assoc" => {
	     "parent"         => "src_ent_oid",
	     "child"          => "tgt_ent_oid",
	 },
	 "BS_biosequence" => {
	     "seq_version"    => "version",
	     "length"         => "length",
	     "seq"            => "seq",
	     "alphabet"       => "alphabet",
	     "division"       => "division",
	     "primary_seq"    => "ent_oid",
	 },
	 "BS_dbxref" => {
	     "database"       => "dbname",
	     "primary_id"     => "accession",
	     "version"        => "version",
	 },
	 "BS_bioentry_dbxref_assoc" => {
	     "rank"           => undef,
	 },
	 "BS_reference" => {
	     "authors"        => "authors",
	     "title"          => "title",
	     "location"       => "location",
	     "medline"        => "document_id",
	     "start"          => "=>BS_bioentry_ref_assoc.start",
	     "end"            => "=>BS_bioentry_ref_assoc.end",
	 },
	 "BS_bioentry_ref_assoc" => {
	     "start"          => "start_pos",
	     "end"            => "end_pos",
	     "rank"           => "rank",
	 },
	 "BS_comment"            => {
	     "text"           => "comment_text",
	     "rank"           => "rank",
	 },
         "BS_ontology_term"      => {
	     "identifier"     => "identifier",
             "name"           => "name",
	     "tagname"        => "name",
             "definition"     => "definition",
             "category"       => "ont_oid",
	     "value"          => "=>{BS_bioentry_qualifier_assoc,BS_seqfeature_qualifier_assoc}.value",
	 },
         "BS_bioentry_qualifier_assoc" => {
	     "value"          => "value",
	     "rank"           => "rank",
	 },
	 "BS_seqfeature"         => {
	     "display_name"   => undef,
	     "rank"           => "rank",
	     "primary_tag"    => "ont_oid",
	     "source_tag"     => "fsrc_oid",
	     "entire_seq"     => "ent_oid",
	 },
	 "BS_seqfeature_location" => {
	     "start"          => "start_pos",
	     "end"            => "end_pos",
	     "strand"         => "strand",
	     "rank"           => "rank",
	 },
	 "BS_seqfeature_qualifier_assoc" => {
	     "value"          => "value",
	     "rank"           => "rank",
	 },
			   );
my %dont_select_attrs = (
	 "BS_biosequence.seq" => 1,
			);

my %acronym_map = (
	 "BS_biodatabase"                => "db",
	 "BS_taxon"                      => "tax",
	 "BS_bioentry"                   => "ent",
	 "BS_bioentry_assoc"             => "enta",
	 "BS_biosequence"                => "seq",
	 "BS_dbxref"                     => "dbx",
	 "BS_bioentry_dbxref_assoc"      => "dbxenta",
	 "BS_reference"                  => "ref",
	 "BS_bioentry_ref_assoc"         => "entrefa",
	 "BS_comment"                    => "cmt",
         "BS_ontology_term"              => "ont",
         "BS_bioentry_qualifier_assoc"   => "entonta",
	 "BS_seqfeature"                 => "fea",
	 "BS_seqfeature_assoc"           => "feaa",
	 "BS_seqfeature_location"        => "loc",
	 "BS_seqfeature_qualifier_assoc" => "feaonta",
			   );
	 

my $schema_sequence = "BS_SEQUENCE";

=head2 new

 Title   : new
 Usage   : my $obj = new Bio::DB::BioSQL::Oracle::BasePersistenceAdaptorDriver();
 Function: Builds a new Bio::DB::BioSQL::Oracle::BasePersistenceAdaptorDriver object 
 Returns : an instance of Bio::DB::BioSQL::Oracle::BasePersistenceAdaptorDriver
 Args    :


=cut

sub new {
    my($class,@args) = @_;

    my $self = $class->SUPER::new(@args);

    # copy into our private hash
    $self->objrel_map(\%object_entity_map);
    $self->slot_attribute_map(\%slot_attribute_map);
    $self->not_select_attrs(\%dont_select_attrs);
    $self->association_entity_map(\%association_entity_map);
    $self->acronym_map(\%acronym_map);
    $self->{'schema_sequence'} = $schema_sequence;

    my ($adp) = $self->_rearrange([qw(ADAPTOR)], @args);
    if($adp) {
	my $dbh = $adp->dbh();
	# set LongReadLen in the database handle if not set already
	if($dbh->{'LongReadLen'} < 0x4000) { # we want at least 16k
	    $dbh->{'LongReadLen'} = 0x20000; # if we got less we demand 128k
	}
    } else {
	$self->warn("-adaptor not supplied, unable to set LOB buffer");
    }

    return $self;
}

=head2 primary_key_name

 Title   : primary_key_name
 Usage   :
 Function: Obtain the name of the primary key attribute for the given table in
           the relational schema.

           For the oracle implementation, this is always oid.

 Example :
 Returns : The name of the primary key (a string)
 Args    : The name of the table (a string)


=cut

sub primary_key_name{
    my ($self,$table) = @_;

    if($table eq "BS_biosequence") {
	return $self->foreign_key_name("Bio::BioEntry");
    }
    return "oid";
}

=head2 foreign_key_name

 Title   : foreign_key_name
 Usage   :
 Function: Obtain the foreign key name for referencing an object, as 
           represented by object, class name, or the persistence adaptor.
 Example :
 Returns : the name of the foreign key (a string)
 Args    : The referenced object, class name, or the persistence adaptor for
           it. 


=cut

sub foreign_key_name{
    my ($self,$obj) = @_;
    my ($table,$fk);

    # if the object is a persistent object and has the foreign_key_slot value
    # set, we start from there
    if(ref($obj) &&
       $obj->isa("Bio::DB::PersistentObjectI") &&
       $obj->foreign_key_slot()) {
	$obj = $obj->foreign_key_slot();
    }
    # default is to get the primary key of the respective table
    $table = $self->table_name($obj);
    if($table) {
	$fk = $self->acronym_map->{$table} ."_oid";
    } elsif(! ref($obj)) {
	my @comps = split(/::/, $obj);
	my $slot = pop(@comps);
	$table = $self->table_name(join("::",@comps));
	if($table) {
	    my $slotmap = $self->slot_attribute_map($table);
	    if($slotmap) {
		$fk = $slotmap->{$slot};
	    }
	}
    }
    return $fk;
}

=head2 sequence_name

 Title   : sequence_name
 Usage   :
 Function: Returns the name of the primary key generator (SQL sequence)
           for the given table.

 Example :
 Returns : the name of the sequence (a string)
 Args    : The name of the table.


=cut

sub sequence_name{
    my ($self,$table) = @_;
    return $table . "_pk_seq";
}

=head2 acronym_map

 Title   : acronym_map
 Usage   : $obj->acronym_map($newval)
 Function: Get/set the map of table names to acronyms (which the oracle
           build consistently uses across the panel).
 Example : 
 Returns : value of acronym_map (a hash ref)
 Args    : on set, new value (a hash ref or undef, optional)


=cut

sub acronym_map{
    my $self = shift;

    return $self->{'acronym_map'} = shift if @_;
    return $self->{'acronym_map'};
}

1;
