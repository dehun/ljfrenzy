#!/usr/bin/perl -w
use strict;

use DBI;
use Getopt::Long;
use Data::Dumper;

require "common/config.pm";
require "common/logger.pm";
require "common/lj.pm";

#
# static
#
my $config_path = "cfg/default_config.xml";
my $config;
my $flush;
my $verbose = 0;
my $dbh;

#
# flush_table
#
sub flush_table()
{
    Logger::info("Flushing table");
    my $prefix = $config->{'db'}->[0]->{'tables_prefix'}->[0];
    $dbh->do("DELETE FROM ".$prefix."_freshmeat");
}

#
# process_friends
#
sub process_friends
{
    my $prefix = $config->{'db'}->[0]->{'tables_prefix'}->[0];
    my @friends = @_;
    my $count = 0;
    foreach my $friend (@friends) {
        #is he in other tables
        Logger::info("processing $friend") if $verbose;
        my $friend_a = $friend;
        $friend_a =~ s/-/_/g;
        #Logger::info($friend_a);
        my $sth = $dbh->prepare("SELECT name FROM ".$prefix."_friends WHERE name='$friend' OR name='$friend_a'");
        $sth->execute();
        next if $sth->fetch();
        $sth = $dbh->prepare("SELECT name FROM ".$prefix."_freshmeat WHERE name='$friend' OR name='$friend_a'");
        $sth->execute();
        next if $sth->fetch();
        $sth = $dbh->prepare("SELECT name FROM ".$prefix."_zombies WHERE name='$friend' OR name='$friend_a'");
        $sth->execute();
        next if $sth->fetch();
        $sth->finish();
        #get time of last post
        my ($sec,$min,$hour,$mday,$mon,$year,$wday, $yday,$isdst)=localtime(time);
        my $timestamp;
        $timestamp = sprintf "%4d-%02d-%02d %02d:%02d:%02d\n", $year+1900, $mon+1, $mday, $hour, $min, $sec;
        my $last_post_date = LJ::get_last_post_date($friend);
        unless (defined($last_post_date)) {
            $dbh->do("INSERT INTO ".$prefix."_zombies (name, turned) VALUES ('$friend','$timestamp')");
            next;
        }
        #print "$friend => $last_post_date\n";
        #it is realy fresh meat - add it
        Logger::info("Adding $friend to ".$prefix."_freshmeat");
        $dbh->do("INSERT INTO ".$prefix."_freshmeat (name, time, last_updated) VALUES('$friend', '$timestamp', '$last_post_date')");
        $count++;
    }
    return $count;
}

#
# harvest_source($)
#
sub harvest_source($)
{
    my ($source) = @_;
    Logger::info("moving across the $source source ");
    my @friends = LJ::get_friends($source) or Logger::error("Can't get friends of $source") and return;
    return @friends;
    
}

#
# process_sources() - processes all the sources from config file
#
sub process_sources()
{
    foreach (@{$config->{'harvester'}->[0]->{'source'}}) {
        my @friends = harvest_source($_);
        my $raw_count = @friends;
        Logger::info("Got $raw_count freshmeat to process from $_");
        my $count = process_friends(@friends);
        Logger::info("Added $count of freshmeat from $_") if $count > 0;
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
        "config:s" => \$cfg,
        "flush!" => \$flush
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
    
    
    if ($flush)
    {
        #flush
        flush_table()
    } else {
        # process sources
        process_sources();
    }
    
    $dbh->disconnect();
}

main(@_);

