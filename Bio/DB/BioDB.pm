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

Bio::DB::BioDB - class providing the context for a particular database

=head1 SYNOPSIS

    $dbc = Bio::DB::BioDB->new(
			-database => 'biosql'
                        -user     => 'root',
                        -dbname   => 'pog',
                        -host     => 'caldy',
			-port     => 3306,    # optional
                        -driver   => 'mysql',
	    );


=head1 DESCRIPTION

This object represents a database that is implemented somehow (you
shouldn\'t care much as long as you can get the object). From the
object you can pull out other adapters, such as the BioSeqAdapter,


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

@ISA = qw(Bio::Root::Root);

my %dbcontext_map = ("biosql" => "Bio::DB::BioSQL",
		     "map"    => "Bio::DB::Map");

my $default_prefix = "Bio::DB";

my @DBC_MODULES = ("DBContext", "dbcontext", "DBAdaptor", "dbadaptor");

BEGIN {
    %LOADED = ();
}

sub new {
    my($pkg, @args) = @_;
    
    my $self = $pkg->SUPER::new(@args);

    my ($biodb) = $self->_rearrange([qw(DATABASE)], @args);
    if(exists($dbcontext_map{lc($biodb)})) {
	$biodb = $dbcontext_map{lc($biodb)};
    } else {
	$biodb = $default_prefix;
    }
    my $dbc_module = $self->_load_dbcontext($biodb);
    return $dbc_module->new(@args);
}

=head2 _load_dbcontext

 Title   : _load_dbcontext
 Usage   : $self->_load_dbcontext("Bio::DB::BioSQL");
 Function: Loads up (like use) the DBContextI implementing module for a
           database at run time on demand.
 Example : 
 Returns : TRUE on success
 Args    : The prefix of the database implementing modules.

=cut

sub _load_dbcontext {
    my ($self, $db) = @_;
    my @msgs = ();

    # check if it's successfully been loaded already before
    return $LOADED{$db} if(exists($LOADED{$db}));
    # try all possibilities
    foreach my $dbc_name (@DBC_MODULES) {
	eval {
	    $self->_load_module($db . "::" . $dbc_name);
	};
	if($@) {
	    push(@msgs, $@);
	} else {
	    $LOADED{$db} = $db . "::" . $dbc_name;
	    last;
	}
    }
    if(! exists($LOADED{$db})) {
	$self->throw("fatal: unable to load DBContext for database $db, ".
		     "(" . join(",", @DBC_MODULES) . ") all failed to load: ".
		     join("\n", @msgs));
    }
    return $LOADED{$db};
}

=head2 _load_module

 Title   : _load_module
 Usage   : $self->_load_module("Bio::DB::BioSQL::DBContext");
 Function: Loads up (like use) the DBContextI implementing module for a
           database at run time on demand.
 Example : 
 Returns : TRUE on success
 Args    : The name of the module to load.

=cut

sub _load_module {
    my ($self, $name) = @_;
    my ($module, $load, $m);
    $module = "_<$name.pm";
    return 1 if $main::{$module};
    $load = "$name.pm";

    my $io = Bio::Root::IO->new();
    # catfile comes from IO
    $load = $io->catfile((split(/::/,$load)));
    eval {
        require $load;
    };
    if ( $@ ) {
        $self->throw("Failed to load module $name. ".$@);
    }
    return 1;
}


1;
