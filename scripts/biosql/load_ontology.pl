#!/usr/local/bin/perl
#
# $Id$
#
# Cared for by Hilmar Lapp <hlapp at gmx.net>
#
# Copyright Hilmar Lapp
#
# You may distribute this module under the same terms as perl itself

#
# (c) Hilmar Lapp, hlapp at gmx.net, 2003.
# (c) GNF, Genomics Institute of the Novartis Research Foundation, 2003.
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

=head1 NAME 

load_ontology.pl

=head1 SYNOPSIS

  # for loading the Gene Ontology:
  load_ontology.pl --host somewhere.edu --dbname biosql \
                   --namespace "Gene Ontology" --format goflat \
                   --fmtargs "-defs_file,GO.defs" \
                   function.ontology process.ontology component.ontology

  # for loading the SOFA part of the sequence ontology (currently
  # there is no term definition file for SOFA):
  load_ontology.pl --host somewhere.edu --dbname biosql \
                   --namespace "SOFA" --format soflat sofa.ontology

=head1 DESCRIPTION

This script loads a bioperl-db with an ontology. There are a number of
options to do with where the bioperl-db database is (ie, hostname,
user for database, password, database name) followed by the database
name you wish to load this into and then any number of files that make
up the ontology. The files are assumed formatted identically with the
format given in the --format flag.

There are more options than the ones shown above. See below.

=head1 ARGUMENTS

The arguments after the named options constitute the filelist. If
there are no such files, input is read from stdin. Mandatory options
are marked by (M). Default values for each parameter are shown in
square brackets.  (Note that -bulk is no longer available):

=over 2 

=item --host $URL

the host name or IP address incl. port [localhost]

=item --dbname $db_name

the name of the schema [biosql]

=item --dbuser $username

database username [root]

=item --dbpass $password

password [undef]

=item --driver $driver

the DBI driver name for the RDBMS e.g., mysql, Pg, or Oracle [mysql]

=item --namespace $namesp 

The namespace (name of the ontology) under which the terms and
relationships in the input files are to be created in the database
[bioperl ontology]. Note that the namespace will be left untouched if the
object(s) to be submitted has it set already.

Note that the DAG-edit flat file parser from more recent (1.2.2 and
later) bioperl releases can auto-discover the ontology name.

=item --lookup

Flag to look-up by unique key first, converting the insert into an
update if the object is found. This pertains to terms only, as there
is nothing to update about relationships if they are found by unique
key (the unique key comprises of all columns).

=item --noupdate

Don't update if object is found (with --lookup). Again, this only
pertains to terms.

=item --remove

Flag to remove terms before actually adding them (this necessitates a
prior lookup). Note that this is not relevant for relationships (if
one is found by lookup, removing and re-adding has essentially the
same result as leaving it untouched).

=item --safe

flag to continue despite errors when loading (the entire object
transaction will still be rolled back)

=item --testonly 

don't commit anything, rollback at the end

=item --format

This may theoretically be any OntologyIO format understood by
bioperl. All input files must have the same format.

Examples: 
    # this is the default
    --format goflat
    # Simple ASCII hierarchy
    --format simplehierarchy

=item --fmtargs

Use this argument to specify initialization parameters for the parser
for the input format. The argument value is expected to be a string
with parameter names and values delimited by comma.

Usually you will want to protect the argument list from interpretation
by the shell, so surround it with double or single quotes.

Examples:

    # turn parser exceptions into warnings (don't try this at home)
    --fmtargs "-verbose,-1"
    # verbose parser with an additional path argument
    --fmtargs "-verbose,1,-indexpath,/home/luke/warp"

=item --mergeobjs

This is a string or a file defining a closure. If provided, the
closure is called if a look-up for the unique key of the new object
was successful (hence, it will never be called without supplying
--lookup, but not --noupdate, at the same time).

The closure will be passed three (3) arguments: the object found by
lookup, the new object to be submitted, and the Bio::DB::DBAdaptorI
(see L<Bio::DB::DBAdaptorI>) implementing object for the desired
database. If the closure returns a value, it must be the object to be
inserted or updated in the database (if $obj->primary_key returns a
value, the object will be updated). If it returns undef, the script
will skip to the next object in the input stream.

The purpose of the closure can be manifold. It was originally
conceived as a means to customarily merge attributes or associated
objects of the new object to the existing (found) one in order to
avoid duplications but still capture additional information (e.g.,
annotation). However, there is a multitude of other operations it can
be used for, like physically deleting or altering certain associated
information from the database (the found object and all its associated
objects will implement Bio::DB::PersistentObjectI, see
L<Bio::DB::PersistentObjectI>). Since the third argument is the
persistent object and adaptor factory for the database, there is
literally no limit as to the database operations the closure could
possibly do.

=item more args

The remaining arguments will be treated as files to parse and load. If
there are no additional arguments, input is expected to come from
standard input.

=back

=head1 Authors

Hilmar Lapp E<lt>hlapp at gmx.netE<gt>

=cut


use Getopt::Long;
use Symbol;
use Carp (qw:cluck confess:);
use Bio::DB::BioDB;
use Bio::OntologyIO;

####################################################################
# Defaults for options changeable through command line
####################################################################
my $host; # should make the driver to default to localhost
my $dbname = "biosql";
my $dbuser = "root";
my $driver = 'mysql';
my $dbpass;
my $format = 'goflat';
my $fmtargs = '';
my $namespace = "bioperl ontology";
my $mergefunc;           # if and how to merge old (found) and new objects
# flags
my $remove_flag = 0;     # remove object before creating?
my $lookup_flag = 0;     # look up object before creating, update if found?
my $no_update_flag = 0;  # do not update if found on look up?
my $help = 0;            # WTH?
my $debug = 0;           # try it ...
my $testonly_flag = 0;   # don't commit anything, rollback at the end?
my $safe_flag = 0;       # tolerate exceptions on create?
####################################################################
# Global defaults or definitions not changeable through commandline
####################################################################

#
# map of I/O type to the next_XXXX method name
#
# Right now there is only a single IO subsystem we support here, so we
# could do well without. We leave it in here to easily be able to adapt
# in the future should it become necessary.
#
my %nextobj_map = (
		   'Bio::OntologyIO' => 'next_ontology',
		   );

####################################################################
# End of defaults
####################################################################

#
# get options from commandline 
#
my $ok = GetOptions( 'host:s'      => \$host,
		     'driver:s'    => \$driver,
		     'dbname:s'    => \$dbname,
		     'dbuser:s'    => \$dbuser,
		     'dbpass:s'    => \$dbpass,
		     'format:s'    => \$format,
		     'fmtargs=s'   => \$fmtargs,
		     'namespace:s' => \$namespace,
		     'mergeobjs:s' => \$mergefunc,
		     'safe'        => \$safe_flag,
		     'remove'      => \$remove_flag,
		     'lookup'      => \$lookup_flag,
		     'noupdate'    => \$no_update_flag,
		     'debug'       => \$debug,
		     'testonly'    => \$testonly_flag,
		     'h'           => \$help,
		     'help'        => \$help
		     );

if((! $ok) || $help) {
    if(! $ok) {
	print STDERR "missing or unsupported option(s) on commandline\n";
    }
    system("perldoc $0");
    exit($ok ? 0 : 2);
}

#
# determine the function for re-throwing exceptions depending on $debug and
# $safe_flag
#
my $throw = $safe_flag ?
    ($debug > 0 ? \&cluck : \&carp) : ($debug > 0 ? \&confess : \&croak);

#
# load and/or parse object merge function if supplied
#
my $merge_objs = parse_code($mergefunc) if $mergefunc;

#
# determine input source(s)
#
my @files = @ARGV ? @ARGV : (\*STDIN);

#
# determine input format and type. Having copy-and-pasted it from
# load_seqdatabase.pl, we support more sophistication than we currently
# need or disclose.
#
my $objio;
my @fmtelems = split(/::/, $format);
if(@fmtelems > 1) {
    $format = pop(@fmtelems);
    $objio = join('::', @fmtelems);
} else {
    # default is OntologyIO
    $objio = "OntologyIO";
}
$objio = "Bio::".$objio if $objio !~ /^Bio::/;
my $nextobj = $nextobj_map{$objio}||"next_ontology"; 
# the format might come with argument specifications
my @fmtargs = split(/\s*,\s*/,$fmtargs);

#
# create the DBAdaptorI for our database
#
my $db = Bio::DB::BioDB->new(-database => "biosql",
			     -host     => $host,
			     -dbname   => $dbname,
			     -driver   => $driver,
			     -user     => $dbuser,
			     -pass     => $dbpass,
			     );
$db->verbose($debug) if $debug > 0;

# declarations
my ($pterm, $adp);

#
# Open the ontology parser on all files supplied. Unlike other IO parsers,
# ontologies may easily involve more than 1 input file to extract the
# entire ontology.
#

# open depending on whether it's a stream or a bunch of files
my $ontin;
my @parserargs = $format ? (-format => $format) : ();
push(@parserargs, @fmtargs);

if(@files == 1) {
    my $fh = $files[0];
    # create a handle if it's not one already
    if(! ref($fh)) {
	$fh = gensym;
	open($fh, "<".$files[0]) or
	    die "unable to open ",$files[0]," for reading: $!\n";
    }
    $ontin = $objio->new(-fh => $fh, @parserargs);
} else {
    $ontin = $objio->new(-files => \@files, @parserargs);
}

# loop over the input stream(s)
while( my $ont = $ontin->$nextobj ) {
    # don't forget to add namespace if the parser doesn't supply one
    $ont->name($namespace) unless $ont->name();

    # in order to allow callbacks to the user and generally a better ability
    # to interfere with and customize the upload process, we load all terms
    # first here instead of simply going for the relationships
    foreach my $term ($ont->get_all_terms()) {
	# look up or delete first?
	my ($lterm);
	if($lookup_flag || $remove_flag) {
	    # look up
	    $adp = $db->get_object_adaptor($term);
	    $lterm = $adp->find_by_unique_key($term,
					      -obj_factory =>
					      $ontin->term_factory());
	    # found?
	    if($lterm) {
		# merge old and new if a function for this is provided
		$term = &$merge_objs($lterm, $term, $db) if $merge_objs;
		# the return value may indicate to skip to the next
		next unless $term;
	    }
	}
	# try to serialize
	eval {
	    $adp = $lterm->adaptor() if $lterm;
	    # delete if requested
	    $lterm->remove() if $remove_flag && $lterm;
	    # on update, skip the rest if we are not supposed to update
	    if(! ($lterm && $no_update_flag)) {
		# create a persistent object out of the term
		$pterm = $db->create_persistent($term);
		$adp = $pterm->adaptor();
		# store the primary key of what we found by lookup (this
		# is going to be an udate then)
		if($lterm && $lterm->primary_key) {
		    $pterm->primary_key($lterm->primary_key);
		}
		$pterm->store();
	    }
	    $adp->commit() unless $testonly_flag;
	};
	if ($@) {
	    my $msg = "Could not store ".$term->object_id().
		" (".$term->name()."): $@\n";
	    $adp->rollback();
	    &$throw($msg);
	}
    }

    # after all terms have been processed, we run through the relationships
    # more or less non-interactively (i.e., without invoking a callback)
    foreach my $rel ($ont->get_relationships()) {
	my $prel = $db->create_persistent($rel);
	eval {
	    $prel->create(); 
	    $prel->commit() unless $testonly_flag;
	};
	if ($@) {
	    my $msg = "Could not store term relationship (".
		join(",",
		     $rel->subject_term->name(),
		     $rel->predicate_term->name(), $rel->object_term()).
		"): $@\n";
	    $prel->rollback();
	    &$throw($msg);
	}
    }
}

$adp->rollback() if $adp && $testonly_flag;
$ontin->close();

# done!

#################################################################
# Implementation of functions                                   #
#################################################################

sub parse_code{
    my $src = shift;
    my $code;

    # file or subroutine?
    if(-r $src) {
	if(! (($code = do $src) && (ref($code) eq "CODE"))) {
	    die "error in parsing code block $src: $@" if $@;
	    die "unable to read file $src: $!" if $!;
	    die "failed to run $src, or it failed to return a closure";
	}
    } else {
	$code = eval $src;
	die "error in parsing code block \"$src\": $@" if $@;
	die "\"$src\" fails to return a closure"
	    unless ref($code) eq "CODE";
    }
    return $code;
}

