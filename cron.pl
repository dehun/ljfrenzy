#!/usr/bin/perl -w
use strict;

use Getopt::Long;
use Data::Dumper;

require "common/config.pm";
require "common/logger.pm";

#
# globals
#
my $config_path = "cfg/default_config.xml";
my $verbose;
my $config;

#
# endless call
#
sub endless_call()
{
    my $granularity = 0;

    for(;;$granularity++) {
        print "Current granularity is $granularity\n" if $verbose;
        
        #harvester
        if ($granularity %  $config->{'cron'}->[0]->{'harvester'}->[0] == 0) {
            Logger::info("launching syncer");
            system("perl syncer.pl    --config=$config_path");
            Logger::info("launching harvester");
            system("perl harvester.pl --config=$config_path");
        }
        
        #friender
        if ($granularity % $config->{'cron'}->[0]->{'friender'}->[0] == 0) {
            Logger::info("launching syncer");
            system("perl syncer.pl   --config=$config_path");
            Logger::info("launching friender");
            system("perl friender.pl --config=$config_path");
        }
       
        #killer
        if ($granularity % $config->{'cron'}->[0]->{'killer'}->[0] == 0) {
            Logger::info("launching syncer");
            system("perl syncer.pl --config=$config_path");
            Logger::info("launching killer");
            system("perl killer.pl --config=$config_path");
        }
        
        #keep granula size
        sleep $config->{'cron'}->[0]->{'granula'}->[0];
    }
}

#
# main
#
sub main
{
    my $cfg;
        GetOptions(
        "verbose!" => \$verbose,
        "config:s" => \$cfg
    );
    
    $config_path = defined($cfg) ? $cfg : $config_path;
    
    #read config
    $config = Config::read_config($config_path) or die("can't read config by path '$config_path'");
    
    # init logger
    #print Dumper($config);
    Logger::init($config->{"logger"}->[0]);
    
    #endless call
    Logger::info("Running with $config_path config");
    Logger::info("Granula size is ". $config->{'cron'}->[0]->{'granula'}->[0] ." seconds" );
    endless_call();
}

main(@_);
