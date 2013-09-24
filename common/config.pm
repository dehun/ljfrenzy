package Config;
use strict;
use warnings;
use XML::Simple;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw();


#
# reads xml config
#
sub read_config($)
{
    my ($config_path) = @_;
    my $xs = new XML::Simple(ForceArray => 1);
    
    my $config = $xs->XMLin($config_path);
    return $config;
}

1;
