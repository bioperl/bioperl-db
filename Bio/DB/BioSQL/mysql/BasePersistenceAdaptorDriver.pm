# $Id$
#
# BioPerl module for Bio::DB::BioSQL::mysql::BasePersistenceAdaptorDriver
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

Bio::DB::BioSQL::mysql::BasePersistenceAdaptorDriver - DESCRIPTION of Object

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
  http://bugzilla.bioperl.org/

=head1 AUTHOR - Hilmar Lapp

Email hlapp at gmx.net

=head1 CONTRIBUTORS

Additional contributors names and emails here

=head1 APPENDIX

The rest of the documentation details each of the object methods.
Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::DB::BioSQL::mysql::BasePersistenceAdaptorDriver;
use vars qw(@ISA);
use strict;

# Object preamble - inherits from Bio::Root::Root

use Bio::DB::BioSQL::BaseDriver;

@ISA = qw(Bio::DB::BioSQL::BaseDriver);

#
# here goes our entire object-relational mapping
#
my %object_entity_map = (
		"Bio::BioEntry"                       => "bioentry",
		"Bio::PrimarySeqI"                    => "bioentry",
		"Bio::DB::BioSQL::PrimarySeqAdaptor"  => "bioentry",
		"Bio::SeqI"                           => "bioentry",
		"Bio::DB::BioSQL::SeqAdaptor"         => "bioentry",
		"Bio::IdentifiableI"                  => "bioentry",
		"Bio::ClusterI"                       => "bioentry",
		"Bio::DB::BioSQL::ClusterAdaptor"     => "bioentry",
		"Bio::DB::BioSQL::BiosequenceAdaptor" => "biosequence",
		"Bio::SeqFeatureI"                    => "seqfeature",
		"Bio::DB::BioSQL::SeqFeatureAdaptor"  => "seqfeature",
		"Bio::Species"                        => "taxon_name",
		"Bio::DB::BioSQL::SpeciesAdaptor"     => "taxon_name",
		# TaxonNode is hack: there is no such object, but we need it
		# to distinguish between the node and the name table
		"TaxonNode"                           => "taxon",
		"Bio::LocationI"                      => "seqfeature_location",
		"Bio::DB::BioSQL::LocationAdaptor"    => "seqfeature_location",
		"Bio::DB::BioSQL::BioNamespaceAdaptor"=> "biodatabase",
		"Bio::DB::Persistent::BioNamespace"   => "biodatabase",
		"Bio::Annotation::DBLink"             => "dbxref",
		"Bio::DB::BioSQL::DBLinkAdaptor"      => "dbxref",
		"Bio::Annotation::Comment"            => "comment",
		"Bio::DB::BioSQL::CommentAdaptor"     => "comment",
		"Bio::Annotation::Reference"          => "reference",
		"Bio::DB::BioSQL::ReferenceAdaptor"   => "reference",
		"Bio::Annotation::SimpleValue"        => "ontology_term",
		"Bio::DB::BioSQL::SimpleValueAdaptor" => "ontology_term",
		"Bio::Annotation::OntologyTerm"       => "ontology_term",
		"Bio::Ontology::TermI"                => "ontology_term",
		"Bio::DB::BioSQL::TermAdaptor"        => "ontology_term",
		   );
my %association_entity_map = (
	 "bioentry" => {
	     "dbxref"         => "bioentry_dbxref",
	     "reference"      => "bioentry_reference",
	     "ontology_term"  => "bioentry_qualifier_value",
	     "bioentry"       => {
		 "ontology_term" => "bioentry_relationship",
	     }
	 },
	 "seqfeature" => {
	     "ontology_term"  => "seqfeature_qualifier_value",
	     "dbxref"         => undef,
	     "reference"      => undef,
	     "seqfeature"     => {
		 "ontology_term" => "seqfeature_relationship",
	     }
	 },
	 "dbxref"   => {
	     "bioentry"       => "bioentry_dbxref",
	     "seqfeature"     => undef,
	 },
	 "reference"   => {
	     "bioentry"       => "bioentry_reference",
	     "seqfeature"     => undef,
	 },
	 "ontology_term" => {
	     "bioentry"       => "bioentry_qualifier_value",
	     "seqfeature"     => "seqfeature_qualifier_value",
	 },
			       );
my %slot_attribute_map = (
	 "biodatabase" => {
	     "namespace"      => "name",
	     "authority"      => "authority",
	 },
	 "taxon_name" => {
	     "classification" => undef,
	     "common_name"    => undef,
	     "ncbi_taxid"     => "ncbi_taxon_id",
	     "binomial"       => "name",
	     "variant"        => undef,
	     # the following are hacks: there is no such thing on
	     # the object model. The sole reason they are here is so that you
	     # can set the physical column name of your taxon_name table.
	     # You MUST have these columns on the taxon node table, NOT the
	     # taxon name table.
	     "name_class"     => "name_class",
	     "node_rank"      => "node_rank",
	     "parent_taxon"   => "parent_taxon_id",
	 },
	 "taxon" => {
	     "ncbi_taxid"     => "ncbi_taxon_id",
	     # the following are hacks, see taxon_name mapping
	     "name_class"     => "name_class",
	     "node_rank"      => "node_rank",
	     "parent_taxon"   => "parent_taxon_id",
	 },
	 "bioentry" => {
	     "display_id"     => "name",
	     "primary_id"     => "identifier",
	     "accession_number" => "accession",
	     "desc"           => "description",
	     "description"    => "description",
	     "version"        => "version",
	     "division"       => "division",
	     "bionamespace"   => "biodatabase_id",
	     "parent"         => "parent_bioentry_id",
	     "child"          => "child_bioentry_id",
	 },
	 "bioentry_relationship" => {
	     "parent"         => "parent_bioentry_id",
	     "child"          => "child_bioentry_id",
	     "rank"           => "rank",
	 },
	 "biosequence" => {
	     "seq_version"    => "version",
	     "length"         => "length",
	     "seq"            => "seq",
	     "alphabet"       => "alphabet",
	     "primary_seq"    => "bioentry_id",
	 },
	 "dbxref" => {
	     "database"       => "dbname",
	     "primary_id"     => "accession",
	     "version"        => "version",
	 },
	 "bioentry_dbxref" => {
	     "rank"           => "rank",
	 },
	 "reference" => {
	     "authors"        => "authors",
	     "title"          => "title",
	     "location"       => "location",
	     "medline"        => "dbxref_id",
	     "doc_id"         => "crc",
	     "start"          => "=>bioentry_reference.start",
	     "end"            => "=>bioentry_reference.end",
	 },
	 "bioentry_reference" => {
	     "start"          => "start_pos",
	     "end"            => "end_pos",
	     "rank"           => "rank",
	 },
	 "comment"            => {
	     "text"           => "comment_text",
	     "rank"           => "rank",
	     "Bio::DB::BioSQL::SeqFeatureAdaptor" => undef,
	 },
         "ontology_term"      => {
	     "identifier"     => "identifier",
             "name"           => "name",
	     "tagname"        => "name",
             "definition"     => "definition",
             #"category"       => "category_id",
	     "value"          => "=>{bioentry_qualifier_value,seqfeature_qualifier_value}.value",
	 },
         "bioentry_qualifier_value" => {
	     "value"          => "value",
	     "rank"           => "rank",
	 },
	 "seqfeature"         => {
	     "display_name"   => "display_name",
	     "rank"           => "rank",
	     "primary_tag"    => "type_term_id",
	     "source_tag"     => "source_term_id",
	     "entire_seq"     => "bioentry_id",
	     "parent"         => "parent_seqfeature_id",
	     "child"          => "child_seqfeature_id",
	 },
	 "seqfeature_location" => {
	     "start"          => "start_pos",
	     "end"            => "end_pos",
	     "strand"         => "strand",
	     "rank"           => "rank",
	 },
	 "seqfeature_qualifier_value" => {
	     "value"          => "value",
	     "rank"           => "rank",
	 },
	 "seqfeature_relationship" => {
	     "parent"         => "parent_seqfeature_id",
	     "child"          => "child_seqfeature_id",
	     "rank"           => "rank",
	 },
			   );
my %dont_select_attrs = (
	 "biosequence.seq" => 1,
			);


=head2 new

 Title   : new
 Usage   : my $obj = new Bio::DB::BioSQL::mysql::BasePersistenceAdaptorDriver();
 Function: Builds a new Bio::DB::BioSQL::mysql::BasePersistenceAdaptorDriver object 
 Returns : an instance of Bio::DB::BioSQL::mysql::BasePersistenceAdaptorDriver
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
    
    return $self;
}

=head2 primary_key_name

 Title   : primary_key_name
 Usage   :
 Function: Obtain the name of the primary key attribute for the given table in
           the relational schema.

           This implementation overrides the default for certain tables that
           do not have their own primary key.
 Example :
 Returns : The name of the primary key (a string)
 Args    : The name of the table (a string)


=cut

sub primary_key_name{
    my ($self,$table) = @_;

    if($table eq "biosequence") {
	$table = $self->table_name("Bio::BioEntry");
    } elsif($table eq "taxon_name") {
	$table = $self->table_name("TaxonNode");
    }
    return $self->SUPER::primary_key_name($table);
}


1;
