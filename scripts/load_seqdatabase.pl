#!/usr/local/bin/perl

=head1 NAME 

load_seqdatabase.pl

=head1 SYNOPSIS

   load_seqdatabase.pl -host somewhere.edu -dbname biosql \
                       -namespace bioperl -format swiss \
                       swiss_sptrembl swiss.dat primate.dat

=head1 DESCRIPTION

This script loads a bioperl-db with sequences. There are a number of
options to do with where the bioperl-db database is (ie, hostname,
user for database, password, database name) followed by the database
name you wish to load this into and then any number of files. The
files are assumed formatted identically with the format given in the
-format flag.

There are more options than the ones shown above. See below.

=head1 ARGUMENTS

  The arguments after the named options constitute the filelist. If
  there are no such files, input is read from stdin. Mandatory options
  are marked by (M). Default values for each parameter are shown in
  square brackets.  (Note that -bulk is no longer available):

  -host    $URL        : the IP addy incl. port [localhost]
  -dbname  $db_name    : the name of the schema (biosql)
  -dbuser  $username   : username [root]
  -dbpass  $password   : password [undef]
  -driver  $driver     : the DBI driver name for the RDBMS
                         e.g., mysql, Pg, or oracle [mysql]
  -format  $FileFormat : format of the flat files [genbank],
                         can be any format read by Bio::SeqIO
  -namespace $namesp   : the namespace under which the sequences in the
                         input files are to be created in the database 
                         [bioperl]
  -seqfilter filter.pl : The sequence filtering function. This is either
                         a string or a file defining a closure to be used
                         as sequence filter. The value is interpreted as 
                         a file if it refers to a readable file, and a
                         string otherwise. Cf. Bio::Seq::SeqBuilder for
                         more information about what the code will be used
                         for, and what it is passed.
  -remove              : flag to remove sequences before actually adding
                         them
  -safe                : flag to continue despite errors when loading
  *file1 file2 file3...: the flatfiles to import
 

=cut


use Getopt::Long;
use Bio::Root::Root;
use Bio::DB::BioDB;
use Bio::Annotation::SimpleValue;
use Bio::SeqIO;
use Bio::ClusterIO;
use Symbol;

####################################################################
# Defaults for options changeable through command line
####################################################################
my $host; # should make the driver to default to localhost
my $dbname = "biosql";
my $dbuser = "root";
my $driver = 'mysql';
my $dbpass;
my $format = 'genbank';
my $namespace = "bioperl";
my $seqfilter;
my $pipeline;
# flags
my $remove_flag = 0;
my $lookup_flag = 0;
my $no_update_flag = 0;
my $help = 0;
my $debug = 0;
#If safe is turned on, the script doesn't die because of one bad entry..
my $safe_flag = 0;
####################################################################
# Global defaults or definitions not changeable through commandline
####################################################################

my %nextobj_map = (
		   'Bio::SeqIO'     => 'next_seq',
		   'Bio::ClusterIO' => 'next_cluster',
		   );

####################################################################
# End of defaults
####################################################################

#
# get options from commandline 
#
my $ok = GetOptions( 'host:s'   => \$host,
		     'driver:s' => \$driver,
		     'dbname:s' => \$dbname,
		     'dbuser:s' => \$dbuser,
		     'dbpass:s' => \$dbpass,
		     'format:s' => \$format,
		     'seqfilter:s' => \$seqfilter,
		     'namespace:s' => \$namespace,
		     'pipeline:s'  => \$pipeline,
		     'safe'     => \$safe_flag,
		     'remove'   => \$remove_flag,
		     'lookup'   => \$lookup_flag,
		     'noupdate' => \$no_update_flag,
		     'debug'    => \$debug,
		     'h' => \$help,
		     'help' => \$help
		     );

if((! $ok) || $help) {
    if(! $ok) {
	print STDERR "missing or unsupported option(s) on commandline\n";
    }
    system("perldoc $0");
    exit($ok ? 0 : 2);
}

#
# load and/or parse condition if supplied
#
my $condition;
if($seqfilter) {
    # file or subroutine?
    if(-r $seqfilter) {
	if(! (($condition = do $seqfilter)) && (ref($condition) eq "CODE")) {
	    die "error in parsing seq filter $seqfilter: $@" if $@;
	    die "unable to read file $seqfilter: $!" if $!;
	    die "failed to run $seqfilter, or it failed to return a closure";
	}
    } else {
	$condition = eval $seqfilter;
	die "error in parsing seq filter \"$seqfilter\": $@" if $@;
	die "\"$seqfilter\" fails to return a closure"
	    unless ref($condition) eq "CODE";
    }
}

#
# determine input source(s)
#
my @files = @ARGV ? @ARGV : (\*STDIN);

#
# determine input format and type
#
my $objio;
($objio,$format) = split(/:/, $format);
if(! $format) {
    $format = $objio;
    # default is SeqIO
    $objio = "SeqIO";
}
$objio = "Bio::".$objio if $objio !~ /^Bio::/;
my $nextobj = $nextobj_map{$objio} || "next_seq"; # next_seq is the default

#
# setup the pipeline if desired
#
my @pipemods = ();
if($pipeline) {
    if($objio ne "Bio::SeqIO") {
	die "pipelining sequence processors not supported for non-SeqIOs\n";
    }
    # split into modules
    my @mods = split(/[,;\|\s]+/, $pipeline);
    # instantiate a module 'loader'
    my $loader = Bio::Root::Root->new();
    # load and instantiate each one, then concatenate
    foreach my $mod (@mods) {
	$loader->_load_module($mod);
	my $proc = $mod->new();
	if(! $proc->isa("Bio::Factory::SequenceProcessorI")) {
	    die "Pipeline processing module $mod does not implement ".
		"Bio::Factory::SequenceProcessorI. Bummer.\n";
	}
	$proc->source_stream($pipemods[$#pipemods]) if @pipemods;
	push(@pipemods, $proc);
    }
    if(! @pipemods) {
	warn "you specified -pipeline, but no processor modules resulted\n";
    }
}

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

# adaptor
my $adp;

#
# loop over every input file and load its content
#
foreach $file ( @files ) {
    
    my $fh = $file;
    my $seqin;

    # create a handle if it's not one already
    if(! ref($fh)) {
	$fh = gensym;
	if(! open($fh, "<$file")) {
	    warn "unable to open $file for reading, skipping: $!\n";
	    next;
	}
	print STDERR "Loading $file ...\n";
    }
    # create stream
    $seqin = $objio->new(-fh => $fh, $format ? (-format => $format) : ());

    # establish filter if provided
    if($condition) {
	if(! $seqin->can('sequence_builder')) {
	    $seqin->throw("object IO parser ".ref($seqin).
			  " does not support control by ObjectBuilderIs");
	}
	$seqin->sequence_builder->add_object_condition($condition);
    }

    # chain to pipeline if pipelining is requested
    if(@pipemods) {
	$pipemods[0]->source_stream($seqin);
	$seqin = $pipemods[$#pipemods];
    }

    # adaptor - we'll set this on demand
    my $adp;

    # loop over the stream
    while( my $seq = $seqin->$nextobj ) {
	# we can't store the structure for structured values yet, so
	# flatten them
	if($seq->can('annotation')) {
	    foreach my $ann ($seq->annotation->remove_Annotations()) {
		if($ann->isa("Bio::Annotation::StructuredValue")) {
		    foreach my $val ($ann->get_all_values()) {
			$seq->annotation->add_Annotation(
				 Bio::Annotation::SimpleValue->new(
					         -value => $val,
						 -tagname => $ann->tagname()));
		    }
		} else {
		    $seq->annotation->add_Annotation($ann);
		}
	    }
	}
	# don't forget to add namespace if the parser doesn't supply one
	$seq->namespace($namespace) unless $seq->namespace();
	# create a persistent object out of the seq
	my ($pseq,$lseq);
	# look up or delete first?
	if($lookup_flag || $remove_flag) {
	    # look up
	    $lseq = $seq->isa("Bio::Seq") ? $seq->primary_seq : $seq;
	    $adp = $db->get_object_adaptor($lseq) unless $adp;
	    $lseq = $adp->find_by_unique_key($lseq);
	    # found?
	    if($lseq) {
		# delete if requested
		$lseq->remove() if $remove_flag;
		# skip the rest if we are not supposed to update
		next if $no_update_flag;
	    }
	}
	# make persistent
	$pseq = $db->create_persistent($seq);
	# store the primary key of we found it by lookup (this is going to
	# be an udate then)
	if($lseq && $lseq->primary_key) {
	    $pseq->primary_key($lseq->primary_key);
	}
	# try to serialize
	eval {
	    if($pseq->primary_key()) {
		$pseq->store();
	    } else {
		$pseq->create();
	    }
	    $pseq->commit();
	};
	if ($@) {
	    my $msg = "Could not store ".$seq->object_id().": $@\n";
	    $pseq->rollback();
	    if($safe_flag) {
		$pseq->warn($msg);
	    } else {
		$pseq->throw($msg);
	    }
	}
    }
    $seqin->close();
}
