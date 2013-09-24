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
my $verbose = 0;
my $dbh;


#
# get_mutual - return mutual friends
#
sub get_mutual($$)
{
    my ($friends, $i_friend_to) = @_;
    my @mutual;
    foreach my $friend (@{$friends}) {
        foreach my $friend_of (@{$i_friend_to}) {
            push(@mutual, $friend) and last if $friend_of eq $friend;
        }
    }
    
    return @mutual;
}

#
# sync_friends
#
sub sync_friends()
{
    #get friends and friends ofs
    my @friends = LJ::get_my_friends($config->{'lj'}->[0]) or Logger::fatal("Can't get friend list");
    my @i_friend_of = LJ::i_friend_to($config->{'lj'}->[0]) or Logger::fatal("Can't get friend list");;
    Logger::info("Gathered info about friends. Processing now");
    
    # build mutual and mutual hash
    my @mutual_friends = get_mutual(\@friends, \@i_friend_of);
    #print $_."\n" foreach (@mutual_friends);
    Logger::info("We have ".($#mutual_friends+1)." mutual friends now");
    
    my %friends_hash;
    foreach my $friend (@friends) {
        $friends_hash{$friend} = grep(/^$friend$/, @mutual_friends);
    #    print $friend . " => ". $friends_hash{$friend} . "\n";
    }
    #print Dumper(%friends_hash);
    
    # get friend list from db
    my  $prefix = $config->{'db'}->[0]->{'tables_prefix'}->[0];
    my $sth = $dbh->prepare("SELECT name, status FROM ".$prefix."_friends");
    my %db_friends;
    my ($db_friend, $status);
	$sth->execute();
    $sth->bind_columns(undef, \$db_friend, \$status);
    $db_friends{$db_friend} = $status while ($sth->fetch());
    $sth->finish();
    
    # update statuses
    my ($sec,$min,$hour,$mday,$mon,$year,$wday, $yday,$isdst)=localtime(time);
    my $timestamp = sprintf "%4d-%02d-%02d %02d:%02d:%02d\n", $year+1900, $mon+1, $mday, $hour, $min, $sec;
    foreach my $friend (@friends) {
        unless (defined ($db_friends{$friend})) {
            #new friend
            my $status = $friends_hash{$friend} ? 'mutual' : 'oneway';
            $dbh->do("INSERT INTO ".$prefix."_friends (name, turned, status) VALUES('$friend', '$timestamp', '$status')");
            Logger::info("New $status friend $friend discovered");
        } else {
            #if this friend already was  - check the status change
            my $status = $db_friends{$friend};
            if ( $status eq 'deleted') {
                
            } elsif ($status eq 'mutual' and not $friends_hash{$friend})
            {
                Logger::info("We were deleted from friends by $friend");
                $dbh->do("UPDATE ".$prefix."_friends SET status='oneway', turned='$timestamp' WHERE name='$friend'");
            } elsif($status eq 'oneway' and $friends_hash{$friend}) {
                Logger::info("New mutual friend - $friend");
                $dbh->do("UPDATE ".$prefix."_friends SET status='mutual', turned='$timestamp' WHERE name='$friend'");
            }
        }
    }
    
    # move deleted friends to zombies
    foreach my $db_friend (keys %db_friends) {
        #Logger::info("Checking $db_friend");
        unless (defined($friends_hash{$db_friend})) {
            Logger::info("Deleting $db_friend and turning it to zombie");
            $dbh->do("DELETE FROM ".$prefix."_friends WHERE name='$db_friend'");
            $dbh->do("INSERT INTO ".$prefix."_zombies (name, turned) VALUES('$db_friend', '$timestamp')");
        }
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
    
    sync_friends();
    
    $dbh->disconnect();
}

main(@_);
