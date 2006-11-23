#!/usr/bin/perl -w

# This is a Module::Build script for bioperl-db installation.
# See http://search.cpan.org/~kwilliams/Module-Build/lib/Module/Build.pm

# Uses a custom subclass of Module::Build called ModuleBuildBioperl that
# doesn't get installed

use strict;
use ModuleBuildBioperl;

# Set up the ModuleBuildBioperl object
my $build = ModuleBuildBioperl->new(
    module_name         => 'Bio',
    dist_name           => 'bioperl-db',
    dist_version        => 1.005002005,
    dist_author         => 'Bioperl Team <bioperl-l@bioperl.org>',
    dist_abstract       => 'bioperl-db - package for biological databases',
    license             => 'artistic',
    requires            => {
                            'perl'                      => '5.6.1',
                            'Bio::Root::Version'        => '1.5.2',
                            'DBI'                       => 0
                           },
    dynamic_config      => 1
    
    #pm_files           => {} # modules in Bio are treated as if they were in lib and auto-installed
    #script_files       => [] # scripts in scripts directory are installed on-demand
);

# Ask questions
biosql_conf();
$build->choose_scripts;

# Add extra things to MANIFEST.SKIP
$build->add_to_manifest_skip('t/DBHarness.biosql.conf');

# Create the build script and exit
$build->create_build_script;

exit;


# setup t/DBHarness.biosql.conf
sub biosql_conf {
    $build->y_n("Have you already installed BioSQL? y/n", 'n') || die "\nBioSQL must be installed prior to installation of bioperl-db; see the INSTALL file\n";
    
    my $config_file = File::Spec->catfile('t', 'DBHarness.biosql.conf');
    if (-e $config_file) {
        $build->y_n("Do you want to use the existing '$config_file' config file? y/n", 'y') && return;
        unlink($config_file);
    }
    
    open(my $out, ">", $config_file) or die "Error: could not write to config file '$config_file'\n";
    
    my %config = (driver     => 'mysql',
                  host       => '127.0.0.1',
                  user       => 'root',
                  port       => 3306,
                  password   => '',
                  dbname     => 'biosql',
                  database   => 'biosql',
                  schema_sql => '../biosql-schema/sql/biosqldb-mysql.sql');
    
    $config{driver} = $build->prompt("DBD driver to use (mandatory)?", $config{driver});
    $config{host} = $build->prompt("Machine to connect to (mandatory)?", $config{host});
    $config{user} = $build->prompt("User to connect to server as (mandatory)?", $config{user});
    
    $config{port} = $build->prompt("Port the server is running on (optional, '' for none)?", $config{port});
    $config{port} = '' if $config{port} eq "''";
    
    $config{password} = $build->prompt("Password (optional)?", $config{password} || 'undef');
    $config{password} = '' if $config{password} eq 'undef';
    
    $build->log_info("
    # The next answer will be used to identify the database name in
    # the connect string, e.g., using database=, dbname=, or sid=,
    # depending on the driver.
    # If this is not set the test scripts will build a temporary
    # database from scratch at the beginning and destroy it at the
    # end. Conversely, if you do set it then the database must exist,
    # or else the tests will fail.
    # Generally, it is preferred to pre-build the database, simply for
    # efficiency reasons, and it will also enable debugging your
    # schema content if some test acts up.
    \n");
    $config{dbname} = $build->prompt("Name of your existing Biosql database, as it is known to your RDBMS (optional, '' for none)?", $config{dbname});
    $config{dbname} = '' if $config{dbname} eq "''";
    
    unless ($config{dbname}) {
        $config{schema_sql} = $build->prompt("Set schema_sql to use the version appropriate for your RDBMS (mandatory)", $config{schema_sql});
    }
    $config{schema_sql} = "['$config{schema_sql}']"; # don't know why it is stored as an array ref, is this correct?
    
    $build->log_info("
    # The next answer does not refer to the schema or RDBMS; it only
    # identifies which of the databases supported in bioperl-db you
    # want to be using. Since at present bioperl-db only supports biosql,
    # this must be biosql.
    \n");
    $config{database} = $build->prompt("The name of the database within bioperl-db?", $config{database});
    
    print $out "{\n";
    while (my ($key, $val) = each %config) {
        $val = "'$val'" unless $key eq 'schema_sql';
        print $out "\t'$key' => $val,\n";
    }
    print $out "}\n";
    close($out);
    
    # we deliberately don't add the config file to cleanup, but it shouldn't
    # cause problems because it is in MANIFEST.SKIP
}
