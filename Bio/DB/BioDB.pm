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

Bio::DB::BioDB - class providing the base adaptor for a particular database

=head1 SYNOPSIS

    $dbadp = Bio::DB::BioDB->new(
			-database => 'biosql'
                        -user     => 'root',
                        -dbname   => 'pog',
                        -host     => 'caldy',
			-port     => 3306,    # optional
                        -driver   => 'mysql',
	    );


=head1 DESCRIPTION

This object represents a database that is implemented somehow (you
shouldn't care much as long as you can get the object). From the
object you can pull out other adapters, such as the BioSeqAdapter etc.


=head1 CONTACT

    Hilmar Lapp, hlapp at gmx.net

=head1 APPENDIX

The rest of the documentation details each of the object methods.
Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::DB::BioDB;

use vars qw(@ISA %LOADED);
use strict;

use Bio::Root::Root;
use Bio::Root::IO;
use Bio::DB::SimpleDBContext;

@ISA = qw(Bio::Root::Root);

my %db_map = ("biosql" => "Bio::DB::BioSQL::",
	      "map"    => "Bio::DB::Map::");

my $default_prefix = "Bio::DB::";

my @DBC_MODULES = ("DBAdaptor", "dbadaptor");

BEGIN {
    %LOADED = ();
}

=head2 new

 Title   : new
 Usage   : $db = Bio::DB::BioDB->new(-database => 'biosql');
 Function: Load and instantiate the encapsulating adaptor for the given
           database.

           This module acts as a factory, similar in spirit to
           Bio::SeqIO, but instead of a sequence stream it returns the
           adaptor object for the specified database.

 Example :
 Returns : a Bio::DB::DBAdaptorI implementing object
 Args    : Named parameters. Currently recognized are
             -database    the name of the database for which the
                          encapsulating adaptor is sought (biosql|markerdb)
             -dbcontext   a Bio::DB::DBContextI implementing object

           Instead of -dbcontext, you can also pass all parameters
           accepted by Bio::DB::SimpleDBContext::new(), and this
           module will create the context for you and set the
           dbadaptor property to the returned value. Note that if you
           do pass in your own DBContextI object, as a side effect the
           dbadaptor() property will be changed by this method to
           reflect the created adaptor.


=cut

sub new {
    my($pkg, @args) = @_;
    
    my $self = $pkg->SUPER::new(@args);

    my ($biodb, $dbc) = $self->_rearrange([qw(DATABASE DBCONTEXT)], @args);
    if(exists($db_map{lc($biodb)})) {
	$biodb = $db_map{lc($biodb)};
    } else {
	$biodb = $default_prefix . $biodb . "::";
    }
    my $dbadp_class = $self->_load_dbadaptor($biodb);
    if(! $dbadp_class) {
	$self->throw("fatal: unable to load DBAdaptor for database: $biodb".
		     "{" . join(",", @DBC_MODULES) . "} all failed to load");
    }
    my $mydbc = $dbc || Bio::DB::SimpleDBContext->new(@args);
    my $dbadp = $dbadp_class->new(-dbcontext => $mydbc);
    # store the adaptor in the context
    $mydbc->dbadaptor($dbadp);
    # success - we hope
    return $dbadp;
}

=head2 _load_dbadaptor

 Title   : _load_dbadaptor
 Usage   : $self->_load_dbadaptor("Bio::DB::BioSQL::");
 Function: Loads up (like use) the DBAdaptorI implementing module for a
           database at run time on demand.
 Example : 
 Returns : TRUE on success
 Args    : The prefix of the database implementing modules.

=cut

sub _load_dbadaptor {
    my ($self, $db) = @_;
    my @msgs = ();

    # check if it's successfully been loaded already before
    return $LOADED{$db} if(exists($LOADED{$db}));
    # try all possibilities
    foreach my $dbadp_name (@DBC_MODULES) {
	eval {
	    $self->_load_module($db . $dbadp_name);
	};
	if($@) {
	    push(@msgs, $@);
	} else {
	    $LOADED{$db} = $db . $dbadp_name;
	    last;
	}
    }
    $self->warn("failed to load dbadaptor: " . join("\n", @msgs))
	if ! $LOADED{$db};
    return $LOADED{$db};
}


1;
