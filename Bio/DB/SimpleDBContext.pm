# $Id$
#
# BioPerl module for SimpleDBContext
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

SimpleDBContext - a base implementation of Bio::DB::DBContextI

=head1 SYNOPSIS

       # See Bio::DB::DBContextI.

=head1 DESCRIPTION

See Bio::DB::DBContextI.

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


package Bio::DB::SimpleDBContext;
use vars qw(@ISA);
use strict;

# Object preamble - inherits from Bio::Root::Root

use Bio::Root::Root;
use Bio::DB::DBContextI;
use Bio::DB::DBI;

@ISA = qw(Bio::Root::Root Bio::DB::DBContextI);

=head2 new

 Title   : new
 Usage   : my $obj = new SimpleDBContext();
 Function: Builds a new SimpleDBContext object 
 Returns : an instance of SimpleDBContext
 Args    :


=cut

sub new {
    my($class,@args) = @_;

    my $self = $class->SUPER::new(@args);
    my ($db,
        $host,
        $driver,
        $user,
        $password,
        $port,
        ) = $self->_rearrange([qw(DBNAME
				  HOST
				  DRIVER
				  USER
				  PASS
				  PORT
				  )],@args);
    $db   || $self->throw("Database object must have a database name");
    $user || $self->throw("Database object must have a user");
    if( ! $driver ) {
        $driver = 'mysql';
    }

    $self->username( $user );
    $self->host( $host ) if defined($host);
    $self->dbname( $db );
    $self->driver($driver);
    $self->password($password) if defined($password);
    $self->port($port) if defined($port);
    return $self;
}

=head2 dbname

 Title   : dbname
 Usage   : $obj->dbname($newval)
 Function: 
 Example : 
 Returns : value of dbname (a scalar)
 Args    : new value (a scalar, optional)


=cut

sub dbname{
    my ($self,$value) = @_;
    if( defined $value) {
	$self->{'dbname'} = $value;
    }
    return $self->{'dbname'};
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
    my ($self,$value) = @_;
    if( defined $value) {
	$self->{'driver'} = $value;
    }
    return $self->{'driver'};
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
    my ($self,$value) = @_;
    if( defined $value) {
	$self->{'username'} = $value;
    }
    return $self->{'username'};
}

=head2 password

 Title   : password
 Usage   : $obj->password($newval)
 Function: 
 Example : 
 Returns : value of password (a scalar)
 Args    : new value (a scalar, optional)


=cut

sub password{
    my ($self,$value) = @_;
    if( defined $value) {
	$self->{'password'} = $value;
    }
    return $self->{'password'};
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
    my ($self,$value) = @_;
    if( defined $value) {
	$self->{'host'} = $value;
    }
    return "localhost" if(! exists($self->{'host'}));
    return $self->{'host'};
}

=head2 port

 Title   : port
 Usage   : $obj->port($newval)
 Function: 
 Example : 
 Returns : value of port (a scalar)
 Args    : new value (a scalar, optional)


=cut

sub port{
    my ($self,$value) = @_;
    if( defined $value) {
	$self->{'port'} = $value;
    }
    return $self->{'port'};
}

=head2 dbadaptor

 Title   : get_adaptor
 Usage   : $dbadp = $dbc->dbadaptor();
 Function:
 Example :
 Returns : An Bio::DB::DBAdaptorI implementing object (an object adaptor
           factory).
 Args    : Optionally, on set an Bio::DB::DBAdaptorI implementing object (to
           be used as the object adaptor factory for the respective database)


=cut

sub dbadaptor{
    my ($self,$value) = @_;
    if( defined $value) {
	$self->{'dbadaptor'} = $value;
    }
    return $self->{'dbadaptor'};
}

=head2 dbi

 Title   : dbi
 Usage   :
 Function:
 Example :
 Returns : A Bio::DB::DBI implementing object
 Args    : Optionally, on set a Bio::DB::DBI implementing object


=cut

sub dbi{
    my ($self,$value) = @_;
    if( defined $value) {
	$self->{'dbi'} = $value;
    }
    if(! exists($self->{'dbi'})) {
	my $dbimod = "Bio::DB::DBI::".$self->driver();
	$self->_load_module($dbimod);
	$self->{'dbi'} = $dbimod->new(-dbcontext => $self);
    }
    return $self->{'dbi'};
}

1;
