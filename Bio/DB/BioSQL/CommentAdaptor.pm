
#
# BioPerl module for Bio::DB::SQL::CommentAdaptor
#
# Cared for by Ewan Birney <birney@ebi.ac.uk>
#
# Copyright Ewan Birney
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::DB::SQL::CommentAdaptor - DESCRIPTION of Object

=head1 SYNOPSIS

Give standard usage here

=head1 DESCRIPTION

Adaptor for Comment objects inside bioperl db 

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


package Bio::DB::SQL::CommentAdaptor;
use vars qw(@ISA);
use strict;
use Bio::Annotation::Comment;

use Bio::DB::SQL::BaseAdaptor;

@ISA = qw(Bio::DB::SQL::BaseAdaptor);

=head2 fetch_by_dbID

 Title   : fetch_by_dbID
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub fetch_by_dbID {
   my ($self,$commentid) = @_;

   my $sth = $self->prepare("select comment_text from comment where comment_id = $commentid");

   $sth->execute;
   my ($text) = $sth->fetchrow_array();

   my $com = Bio::Annotation::Comment->new();
   $com->text($text);

   return $com;
}



=head2 fetch_by_bioentry_id

 Title   : fetch_by_bioentry_id
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub fetch_by_bioentry_id{
   my ($self,$bioentry_id) = @_;

   # yes - not optimised. We could removed quite a few nested gets here
   my $sth = $self->prepare("select comment_id from comment where bioentry_id = $bioentry_id order by comment_rank");
   $sth->execute;

   my @out;
   while( my $arrayref = $sth->fetchrow_arrayref )  {
       my ($biodblink_id) = @{$arrayref};
       push(@out,$self->fetch_by_dbID($biodblink_id));
   }

   
   return @out;
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
   my ($self,$comment,$rank,$bioentry_id) = @_;

   if( !defined $bioentry_id ) {
       $self->throw("Must store comemnts with bioentry_id");
   }
   my $text = $comment->text;
   $text =~ s/\'/\\\'/g;
   my $sth = $self->prepare("insert into comment (comment_id,bioentry_id,comment_text,comment_rank) values (NULL,$bioentry_id,'$text',$rank)");
   $sth->execute();

}



