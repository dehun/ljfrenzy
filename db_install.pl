#!/usr/bin/perl -w
use strict;
use Getopt::Long;
use Data::Dumper;
use DBI;

require "common/db.pm";
require "common/config.pm";
require "common/logger.pm";

#
# static
#
my $config_path = "cfg/default_config.xml";
my $config;
my $verbose = 0;
my $dbh;
#
# main
#
sub main {
    # get opt
    my $cfg;
    GetOptions(
        "v|verbose+" => \$verbose,
        "c|config:s" => \$cfg
    );
    $config_path = defined($cfg) ? $cfg : $config_path;
    
    #read config
    $config = Config::read_config($config_path) or die("can't read config by path '$config_path'");
    
    # init logger
    #print Dumper($config);
    Logger::init($config->{"logger"}->[0]);
    Logger::info("Installing new dbs with db_prefix " . $config->{'db'}->[0]->{'tables_prefix'}->[0]);
    
    # opening db connection
    $dbh = DBI->connect($config->{'db'}->[0]->{'dbi_path'}->[0],
                        $config->{'db'}->[0]->{'user'}->[0],
                        $config->{'db'}->[0]->{'password'}->[0],
                        { RaiseError => 1 }) or Logger::error("Can't connect to db") and die();
    Logger::info("connected to db");
    # do all da shit
    
    #friends table
    #foreach (DBI->avalibe_drivers()) { print "$_\n" };
    my  $prefix = $config->{'db'}->[0]->{'tables_prefix'}->[0];
    $dbh->do("CREATE TABLE ".$prefix."_friends (
                            id INTEGER AUTO_INCREMENT PRIMARY KEY,
                            name VARCHAR(256),
                            status VARCHAR(64),
                            turned VARCHAR(64)
                            )") or Logger::fatal("Can't create table friends");
    Logger::info("table ".$prefix."_friends successfully created");
    
    #zombies table
    $dbh->do("CREATE TABLE ". $prefix . "_zombies (
                            id INTEGER AUTO_INCREMENT PRIMARY KEY,
                            name VARCHAR(256),
                            turned VARCHAR(64)
                            )");
     Logger::info("table ".$prefix."_zombies successfully created");
    #freshmeat
    $dbh->do("CREATE TABLE ". $prefix . "_freshmeat (
                            id INTEGER AUTO_INCREMENT PRIMARY KEY,
                            name VARCHAR(256),
                            time VARCHAR(64),
                            last_updated INTEGER
                          )");
     Logger::info("table ".$prefix."_freshmeat successfully created");
    
    #cleanup
    $dbh->disconnect();
    
    
}

main(@_);
