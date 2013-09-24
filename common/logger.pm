package Logger;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw();

require Log::Log4perl;

#
# static
#
my $logger;

#
# init() - initializes logger
#
sub init($)
{
    my ($log_config) = @_;
#

#
    my $log_conf = "
            log4perl.category = INFO, Screen, Logfile\n

            

            log4perl.appender.Screen        = Log::Log4perl::Appender::Screen\n
            log4perl.appender.Screen.stderr = 0\n
            log4perl.appender.Screen.layout = Log::Log4perl::Layout::PatternLayout\n
            log4perl.appender.Screen.layout.ConversionPattern = %d %p> %m%n\n
            
            log4perl.appender.Logfile = Log::Log4perl::Appender::File\n
            log4perl.appender.Logfile.filename = $log_config->{'filepath'}->[0]\n
            log4perl.appender.Logfile.mode = append\n
            log4perl.appender.Logfile.layout = Log::Log4perl::Layout::PatternLayout\n
            log4perl.appender.Logfile.layout.ConversionPattern = %d %p> %m%n\n

            log4perl.logger.main = INFO\n
        ";
        Log::Log4perl::init(\$log_conf);
        $logger = Log::Log4perl::Logger->get_logger("main");
}

#
# die_uninitializers
#
sub die_uninitializers()
{
    die("logger uninitialized but was called") unless $logger; 
}

#
# info
#
sub info
{
    die_uninitializers();
    $logger->info(@_);
}

#
# warning
#
sub warning
{
    die_uninitializers();
    $logger->warning(@_)
}

#
# error
#
sub error
{
    die_uninitializers();
    $logger->error(@_);
}


1;
