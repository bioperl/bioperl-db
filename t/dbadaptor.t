# -*-Perl-*-
# $Id$

use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;    
    plan tests => 5;
}

use BioSQLBase;
use Bio::DB::BioSQL::DBAdaptor;


$biosql = BioSQLBase->new();
ok $biosql;

my $db = $biosql->db();
ok $db;

# test connection
my $rc = $db->_db_handle()->ping();
ok ($rc && ($rc ne '0 but true'));

# execute some SQL that must work
my $sth = $db->prepare("SELECT count(*) FROM biodatabase");
$sth->execute();

ok $sth;
my @n = $sth->fetchrow_array();
ok (scalar(@n), 1);

$sth->finish();



