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
files are assumed to be SeqIO formatted files with the format given
in the -format flag.


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
                         for.
  -remove              : flag to remove sequences before actually adding
                         them
  -safe                : flag to continue despite errors when loading
  *file1 file2 file3...: the flatfiles to import
 

=cut


use Getopt::Long;
use Bio::DB::BioDB;
use Bio::Annotation::SimpleValue;
use Bio::SeqIO;

####################################################################
# Defaults for options changeable through command line
####################################################################
my $host = "localhost";
my $dbname = "biosql";
my $dbuser = "root";
my $driver = 'mysql';
my $dbpass;
my $format = 'genbank';
my $namespace = "bioperl";
my $seqfilter;
# flags
my $remove_flag = 0;
my $help = 0;
my $debug = 0;
#If safe is turned on, the script doesn't die because of one bad entry..
my $safe_flag = 0;
####################################################################
# End of defaults
####################################################################

my $ok = GetOptions( 'host:s'   => \$host,
		     'driver:s' => \$driver,
		     'dbname:s' => \$dbname,
		     'dbuser:s' => \$dbuser,
		     'dbpass:s' => \$dbpass,
		     'format:s' => \$format,
		     'seqfilter:s' => \$seqfilter,
		     'namespace:s' => \$namespace,
		     'safe'     => \$safe_flag,
		     'remove'   => \$remove_flag,
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

my @files = @ARGV;
# if no files, assume stdin
if(! @files) {
    push(@files, \*STDIN);
}

my $db = Bio::DB::BioDB->new(-database => "biosql",
			     -host     => $host,
			     -dbname   => $dbname,
			     -driver   => $driver,
			     -user     => $dbuser,
			     -pass     => $dbpass,
			     );

$db->verbose($debug) if $debug > 0;

foreach $file ( @files ) {

    my $seqin;
    if(ref($file)) {
	$seqin = Bio::SeqIO->new(-fh => $file, -format => $format);
    } else {
	print STDERR "Loading $file\n";
	$seqin = Bio::SeqIO->new(-file => $file,
				 $format ? (-format => $format) : ());
    }
    # establish filter if provided
    if($condition) {
	$seqin->sequence_builder->add_object_condition($condition);
    }

    while( my $seq = $seqin->next_seq ) {
	# we can't store the structure for structured values yet, so flatten
	# them
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
	# don't forget to add namespace if the parser doesn't supply one
	$seq->namespace($namespace) unless $seq->namespace();
	# create a persistent object out of the seq
	my $pseq;
	# delete first?
        if ($remove_flag) {
	    $pseq = $db->get_object_adaptor($seq)->find_by_unique_key($seq);
	    $pseq->remove() if($pseq);
        } else {
	    $pseq = $db->create_persistent($seq);
	}
	# try to serialize
	eval {
	    $pseq->create();
	    $pseq->commit();
	};
	if ($@) {
	    my $msg = "Could not store ".$seq->accession.": $@\n";
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
