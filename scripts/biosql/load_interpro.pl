use strict;
use Bio::OntologyIO::Handlers::InterPro_BioSQL_Handler;
use XML::Parser::PerlSAX;
use Bio::DB::EasyArgv;
use Getopt::Long;


my $db = get_biosql_db_from_argv;
my ($file, $version);
GetOptions(
    'file=s' => \$file,
    'version=s' => $version
);

my $handler = Bio::OntologyIO::Handlers::InterPro_BioSQL_Handler->new(
    -db => $db,
    -version => "version $version"
);
my $parser = XML::Parser::PerlSAX->new(Handler=>$handler);
my $ret = $parser->parse(Source=>{SystemId=>$file});
