# $Id$

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

Bio::DB::DBContextI - Interface for a class implementing a database context

=head1 SYNOPSIS

    # obtain a DBContextI implementing object somehow, usually through
    # a factory, for example
    use Bio::DB::BioDB;

    $dbcontext = Bio::DB::BioDB->new(
			-database => 'biosql'
                        -user     => 'root',
                        -dbname   => 'pog',
                        -host     => 'caldy',
			-port     => 3306,    # optional
                        -driver   => 'mysql',
	    );

    # obtain other adaptors as needed
    $seq_adaptor = $dbc->get_adaptor('Bio::PrimarySeqI');

=head1 DESCRIPTION

This object represents the context of a database that is implemented somehow.

=head1 CONTACT

    Hilmar Lapp, hlapp at gmx.net

=head1 APPENDIX

The rest of the documentation details each of the object methods. Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::DB::DBContextI;

use vars qw(@ISA);
use strict;

use Bio::Root::RootI;

@ISA = qw(Bio::Root::RootI);


=head2 dbname

 Title   : dbname
 Usage   : $obj->dbname($newval)
 Function: 
 Example : 
 Returns : value of dbname (a scalar)
 Args    : new value (a scalar, optional)


=cut

sub dbname{
    my ($self) = @_;
    $self->throw_not_implemented();
}

=head2 driver

 Title   : driver
 Usage   : $obj->driver($newval)
 Function: 
 Example : 
 Returns : value of driver (a scalar)
 Args    : new value (a scalar, optional)


=cut

sub driver{
    my ($self) = @_;
    $self->throw_not_implemented();
}

=head2 username

 Title   : username
 Usage   : $obj->username($newval)
 Function: 
 Example : 
 Returns : value of username (a scalar)
 Args    : new value (a scalar, optional)


=cut

sub username {
    my ($self) = @_;
    $self->throw_not_implemented();
}

=head2 host

 Title   : host
 Usage   : $obj->host($newval)
 Function: 
 Example : 
 Returns : value of host (a scalar)
 Args    : new value (a scalar, optional)


=cut

sub host {
    my ($self) = @_;
    $self->throw_not_implemented();
}

=head2 get_adaptor

 Title   : get_adaptor
 Usage   : $seq_adaptor = $dbc->get_adaptor('Bio::PrimarySeqI');
 Function:
 Example :
 Returns : An instance of an adaptor class suitable for the given class
           and the database represented by this context.
 Args    : The name of the class or interface for which to obtain an
           adaptor class for.


=cut

sub get_adaptor{
    my ($self) = @_;
    $self->throw_not_implemented();
}

=head2 dbh

 Title   : dbh
 Usage   : $dbh = $obj->dbh()
 Function: 
 Example : 
 Returns : The current database connection handle (see DBI)
 Args    : New connection handle on set (optional)


=cut

sub dbh {
    my ($self) = @_;
    $self->throw_not_implemented();
}

1;
