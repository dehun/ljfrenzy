#!/usr/bin/perl -w
use strict;

use DBI;
use Getopt::Long;
use Data::Dumper;
use Time::Local;

require "common/config.pm";
require "common/logger.pm";
require "common/lj.pm";

#
# static
#
my $config_path = "cfg/default_config.xml";
my $config;
my $verbose = 0;
my $dbh;

#
# kill suspended
#
sub kill_suspended
{
    #my $tokill = $config->{'killer'}->[0]->{'friends_per_launch'}->[0];
    my @suspended = LJ::get_my_suspended($config->{'lj'}->[0]);
    foreach my $friend (@suspended) {
        Logger::info("Killing suspended friend $friend\n");
        LJ::delete_friend($config->{'lj'}->[0], $friend) or Logger::error("Can't delete $friend");
    }
}

#
# kill_friends
#
sub kill_friends
{
    my $oneway_ttl = $config->{'killer'}->[0]->{'oneway_ttl'}->[0];
    my $prefix = $config->{'db'}->[0]->{'tables_prefix'}->[0];
    my $tokill = $config->{'killer'}->[0]->{'friends_per_launch'}->[0];
    Logger::info("Going to kill $tokill friends in this launch");
    my $sth = $dbh->prepare("SELECT name, turned FROM ".$prefix."_friends WHERE status='oneway'");
    my ($name, $turned) ;
    my @doomed;
	$sth->execute();
    $sth->bind_columns(undef, \$name, \$turned); 
    while ($sth->fetch()) {
        my ($year, $month, $day, $hour, $minute, $second) = $turned =~ /^([0-9]{4})-([0-9]{2})-([0-9]{2})\ ([0-9]{2}):([0-9]{2}):([0-9]{2})$/;
        my $timestamp = timegm($second, $minute, $hour, $day, $month -1, $year);
        my $current_time = timegm(localtime());
        my $diff = $current_time - $timestamp;
	#Logger::info("$name => $diff");
      
        if ($diff > $oneway_ttl) {
		Logger::info("$name will be killed now") if $verbose;
            push(@doomed, $name);
            #print "$name\n";
        } else {
              Logger::info("$name will be killed in ". ($oneway_ttl - $diff)) if $verbose;
        }
    }
    $sth->finish();
    my $killed = 0;
    foreach my $friend (@doomed) {
        #last if ($killed++ => $tokill);
        Logger::info("Killing $friend to zombies");
        LJ::delete_friend($config->{'lj'}->[0], $friend) or Logger::error("Can't kill friend $friend");
    }
}

#
# main
#
sub main
{
    my $cfg;
    GetOptions(
        "verbose+" => \$verbose,
        "config:s" => \$cfg
    );
    $config_path = defined($cfg) ? $cfg : $config_path;
    
    #read config
    $config = Config::read_config($config_path) or die("can't read config by path '$config_path'");
    
    # init logger
    #print Dumper($config);
    Logger::init($config->{"logger"}->[0]);
    
    # opening db connection
    $dbh = DBI->connect($config->{'db'}->[0]->{'dbi_path'}->[0],
                        $config->{'db'}->[0]->{'user'}->[0],
                        $config->{'db'}->[0]->{'password'}->[0],
                        { RaiseError => 1 }) or Logger::error("Can't connect to db") and die();
    Logger::info("connected to db");
    
    kill_friends();
    kill_suspended();
    
    $dbh->disconnect();
}

main(@_);
