# $Id$
#
# BioPerl module for Bio::DB::SQL::DBXrefAdaptor
#
# Cared for by Ewan Birney <birney@ebi.ac.uk>
#
# Copyright Ewan Birney
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::DB::SQL::DBXrefAdaptor - DBXref Adaptor

=head1 SYNOPSIS

Do not use create this object directly

=head1 DESCRIPTION

Adaptor for DBXrefs 

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


package Bio::DB::SQL::DBXrefAdaptor;
use vars qw(@ISA);
use strict;
use Bio::Annotation::DBLink;
use Bio::DB::SQL::BaseAdaptor;

@ISA = qw(Bio::DB::SQL::BaseAdaptor);

sub _table {"dbxref"}


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

   my $sth = $self->prepare("select dbname,accession from dbxref where dbxref_id = $dbid");
   $sth->execute;

   my ($dbname,$acc) = $sth->fetchrow_array();

   my $dblink = Bio::Annotation::DBLink->new();

   $dblink->database($dbname);
   $dblink->primary_id($acc);

   my @hl =
     $self->selectall("dbxref_qualifier_value",
                      "dbxref_id = $dbid");
   my $oad = $self->db->get_OntologyTermAdaptor;
   foreach my $h (@hl) {
       my $tid = $h->{ontology_term_id};
       my $qv  = $h->{qualifier_value};
       if ($tid == $oad->COMMENT_ID) {
           $dblink->comment($qv);
       }
       elsif ($tid == $oad->OPTIONAL_ID_ID) {
           $dblink->optional_id($qv);
       }
       else {
           $self->throw("Don't know what to do with a term:$tid in this context");
       }
   }
   return $dblink;
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
   my ($self,$dbxref) = @_;

   my $acc = $dbxref->primary_id();
   my $db  = $dbxref->database();

   my $id;
   my $h =
     {dbname=>$db,
      accession=>$acc};
   $id =
     $self->select_colval("dbxref",
                          $h,
                          "dbxref_id");
   if ($id) {
   }
   else {
       $id =
         $self->insert("dbxref",
                       $h);
   }
   if ($dbxref->optional_id) {
       my $TERM_ID =
         $self->db->get_OntologyTermAdaptor->OPTIONAL_ID_ID;
       $self->deleterows("dbxref_qualifier_value",
                         {dbxref_id=>$id,
                          ontology_term_id=>$TERM_ID});
       $self->insert("dbxref_qualifier_value",
                     {dbxref_id=>$id,
                      ontology_term_id=>$TERM_ID,
                      qualifier_value=>$dbxref->optional_id});
   }
   if ($dbxref->comment) {
       my $TERM_ID =
         $self->db->get_OntologyTermAdaptor->COMMENT_ID;
       $self->deleterows("dbxref_qualifier_value",
                         {dbxref_id=>$id,
                          ontology_term_id=>$TERM_ID});
       $self->insert("dbxref_qualifier_value",
                     {dbxref_id=>$id,
                      ontology_term_id=>$TERM_ID,
                      qualifier_value=>$dbxref->comment});
   }
   
   return $id;
}


1;
