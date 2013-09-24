#!/usr/bin/perl -w
use strict;

use Getopt::Long;

my $configs_path = "./cfg/";
my $verbose;

sub main(@)
{
    #getopt
    my $cfg;
    GetOptions(
        "verbose+" => \$verbose,
        "configs:s" => \$cfg
    );
    
    my $configs_path = defined($cfg) ? $cfg : $configs_path;
    
    #run through configs and fork for each
    print $configs_path;
    opendir(DIR, $configs_path);
    my @files = readdir(DIR);
    @files = grep (/\.xml$/, @files);
    
    foreach my $file (@files) {
        print("Launching cron for $file '"."perl cron.pl --config=$configs_path/$file"."'");
        system("perl cron.pl --config=$configs_path/$file") unless(fork());
    }
    
}

main(@_);
