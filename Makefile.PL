
%packages =(); 

sub check_package {
    my ($name,$str) = @_;
    my($ver,$desc,$expl,@modules);

    ($ver,$desc,$expl,$module) = split( /\// , $str);
    if( !eval "require $name") {
	print "External Module $name, $desc,\n is not installed on this computer.\n  The $module in Bioperl needs it for $expl\n\n";
	return 1;
    }

    return 0;
}


# Generate sub testing package system
#
#

# make mini test targets for playing around with
# in testing...

opendir(DIR,"t") || warn "No test directory. Weird!";
@files = readdir(DIR);
shift @files;
shift @files;
foreach my $file (@files) {
    $file =~ /(\w+)\.t/ || next;
    $file = $1;
    $line = "test_$file :: pure_all\n\tPERL_DL_NONLAZY=1 \$(FULLPERL) -I\$(INST_ARCHLIB) -I\$(INST_LIB) -I\$(PERL_ARCHLIB) -I\$(PERL_LIB) -e \'use Test::Harness qw(&runtests \$\$verbose); \$\$verbose=\$(TEST_VERBOSE); runtests \@ARGV;\' t/$file.t\n";
    push(@tline,$line);
    push(@targets,$file);
    $tset  .= "$file \\\n";
}

$tline = join('',@tline);
$tline = "show_tests :\n\t\@echo \'type make test_<subtest> to run\'\n\t\@echo '$tset'\n$tline\n";

print STDERR "Generated sub tests. go make show_tests to see available subtests\n";

sub MY::postamble {
             $tline;
           }


				           
use ExtUtils::MakeMaker;
require 5.004;
$NAME     = 'Bio';
$DISTNAME = "bioperl-db";
$VERSION  = "0.01";

$error = 0;
foreach $name ( keys %packages ) {
    if( &check_package($name,$packages{$name}) == 1 ) {
	$error = 1;
    }
}

if( $error == 1 ) {
    print <<QQ_ERROR_QQ;

Warning:

   There are some external packages, listed above, which bioperl 
   uses. This only effects the functionality which is listed above:
   the rest of bioperl will work fine.

   The installation of these external packages is very simple. You
   can read more about the external packages at

   http://bio.perl.org/Core/external.shtml

   The ftp site

   ftp://bio.perl.org/pub/external/

   has all the external packages for easy retrieval, or you can use CPAN

   Enjoy the rest of bioperl, which you can use after going 'make install'

QQ_ERROR_QQ
}

@BACKUP_FILES = ();

WriteMakefile(
	      NAME	=> $NAME,
	      DISTNAME  => $DISTNAME,
	      VERSION   => $VERSION,
	      'dist'    => {  COMPRESS     => 'gzip -9f',
			      SUFFIX       => '.gz', 
			      DIST_DEFAULT => 'all tardist',
			  },
	      'realclean' => { FILES       => join( ' ', @BACKUPFILES) }
	      );
