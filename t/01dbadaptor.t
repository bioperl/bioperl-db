# -*-Perl-*-
# $Id$

use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;    
    plan tests => 6;
}

use BioSQLBase;
use Bio::DB::BioSQL::DBAdaptor;


my $biosql = DBTestHarness->new("biosql");
ok $biosql;

my $dbc = $biosql->get_DBContext();
ok $dbc;

my $db = $dbc->dbadaptor();
ok $db->isa("Bio::DB::DBAdaptorI");
ok $db->isa("Bio::DB::BioSQL::DBAdaptor");

# test connection
my $dbh = $dbc->dbi()->new_connection($dbc);
ok $dbh;
my $rc = $dbh->ping();
ok ($rc && ($rc ne '0 but true'));

$dbh->disconnect();



