#!/usr/bin/perl -w
use strict;

use DBI;
use Getopt::Long;
use Data::Dumper;
use LWP::Simple;

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
# get out urls
#
sub get_out_urls($)
{
    my ($name) = @_;
    my $page_src =  LWP::Simple::get("http://$name.livejournal.com/");
    #print $page_src;
    my $count_href = 0;
    
    my $url;
    while(($page_src =~ /(<a\ *href\ *=\ *["|']{0,1}.+?["|']{0,1}\ )/gi) ) {
        $url = $1;
        next if $url =~ /livejournal\.com/i;
	next if $url =~ /livejournal\.ru/i;
        next if $url =~  /lj-toys\.com/i;
        next if $url =~ /#/i;
        next if $url =~ /sol\.adbureau\.net/i;
        next if $url =~ /ljplus\.ru/i;
        next if $url =~ /google\.[ru|com]/i;
	next if $url =~ /last\.fm/i;
	next if $url =~ /radikal\.ru/i;
	next if $url =~ /fotki/i;
	next if $url =~ /flickr/;
#	next if $url =~ /twitter/;
	next if $url =~ /cs.+?(vk|vkontakte)/i;
	next if $url =~ /ljonmap/i;
        $count_href++;
 #      print "$url\n";
    }

    my $count_h2 = my (@list2) = $page_src =~ /subj-link/gi;
#    print "h2 : $count_h2\nhrefs : $count_href\n ";
    return 999999999 if ($count_h2 == 0);
    return $count_href/$count_h2;
}


#
# add_friends
#
sub add_friends
{
    my ($tofriend) = @_;
    my $prefix = $config->{'db'}->[0]->{'tables_prefix'}->[0];

    Logger::info("Going to friend $tofriend friends in this launch");
    my $sth = $dbh->prepare("SELECT distinct(name) FROM ".$prefix."_freshmeat ORDER BY last_updated DESC LIMIT $tofriend");
    my $name;
    my @future_friends;
	$sth->execute();
    $sth->bind_columns(undef, \$name);
    push(@future_friends, $name) while ($sth->fetch()); $sth->finish();
	my $friended = 0;
    foreach my $friend (@future_friends) {
        if (get_out_urls($friend) < 2) {
            
            Logger::info("Adding $friend to friends");
            
            unless (LJ::add_friend($config->{'lj'}->[0], $friend)) {
                Logger::error("Can't add to friend $friend");
            }
            $friended++;
        } else {
            Logger::info("Skipping possible bot $friend");
        }
        
        $dbh->do("DELETE FROM ".$prefix."_freshmeat WHERE name='$friend'");
    }
    add_friends($tofriend - $friended) if ($friended < $tofriend);
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

    my $tofriend = $config->{'friender'}->[0]->{'friends_per_launch'}->[0];    
    add_friends($tofriend);
    
    $dbh->disconnect();
}

main(@_);
