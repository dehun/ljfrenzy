package LJ;
use strict;
use warnings;
use XMLRPC::Lite;
use Digest::MD5 qw(md5_hex);
use Data::Dumper;
use LWP::Simple;
use Time::Local;

#require Exporter;
#our @ISA = qw(Exporter);
#our @EXPORT_OK = qw();

#
# get_my_friends - returns 
#
sub get_my_friends($)
{
    my ($lj_config) = @_;
    my $client = XMLRPC::Lite->proxy($lj_config->{'xmlrpc_interface'}->[0]); 
    my $challenge = $client->call("LJ.XMLRPC.getchallenge")->result->{'challenge'}; 
    my $response = md5_hex($challenge . md5_hex($lj_config->{'password'}->[0]));
    my $res = $client->call(
                            'LJ.XMLRPC.getfriends',{
                            'username' => $lj_config->{'user'}->[0],
                            'authmethod' => 'clear',
                            'password' => $lj_config->{'password'}->[0]}
                            #'auth_challenge' => $challenge, 
                	    #'auth_response'  => $response}
                            )->result;
    return undef() unless defined $res; 
    my @friends;
    foreach my $friend (@{$res->{'friends'}}) {
        push @friends, $friend->{'username'} unless (defined($friend->{'type'}) or defined($friend->{'status'})) ; 
    }
    sleep $lj_config->{'sleep'}->[0];
    return @friends;
}

#
# get_my_suspended - returns my suspended friends
#
sub get_my_suspended($)
{
    my ($lj_config) = @_;
    my $client = XMLRPC::Lite->proxy($lj_config->{'xmlrpc_interface'}->[0]); 
    my $challenge = $client->call("LJ.XMLRPC.getchallenge")->result->{'challenge'}; 
    my $response = md5_hex($challenge . md5_hex($lj_config->{'password'}->[0]));
    my $res = $client->call(
                            'LJ.XMLRPC.getfriends',{
                            'username' => $lj_config->{'user'}->[0],
                            'authmethod' => 'clear',
                            'password' => $lj_config->{'password'}->[0]}
                            #'auth_challenge' => $challenge, 
                	    #'auth_response'  => $response}
                            )->result;
    return undef() unless defined $res; 
    my @friends;
    foreach my $friend (@{$res->{'friends'}}) {
        push @friends, $friend->{'username'} if ( not defined($friend->{'type'}) and defined($friend->{'status'})) ; 
    }
    sleep $lj_config->{'sleep'}->[0];
    return @friends;
}
#
# get_friends - get friend list of somebody
#
sub get_friends($)
{
    my ($source) = @_;
    my @friends;
    my $page_src =  LWP::Simple::get("http://www.livejournal.com/tools/friendlist.bml?user=$source&nopics=1") or return undef();
    #$page_src =~ s/<strike>.+<\/strike>//gi;
    #push(@friends, $1) while ($page_src =~ /lj:user="(.+?)"/ig);
    push(@friends, $1) while ($page_src =~ /"http:\/\/(.+?)\.livejournal.com\/profile"/ig);
    #push(@friends, $1) while ($page_src =~ /<a\ href="http:\/\/([0-9a-zA-Z\-_]+)\.livejournal\.com"/ig);
    return @friends;
}

#
# i_friend_to - returs list of users i friend to
#
sub i_friend_to($)
{
    my ($lj_config) = @_;
    my $client = XMLRPC::Lite->proxy($lj_config->{'xmlrpc_interface'}->[0]); 
    my $challenge = $client->call("LJ.XMLRPC.getchallenge")->result->{'challenge'}; 
    my $response = md5_hex($challenge . md5_hex($lj_config->{'password'}->[0]));
    my $res = $client->call(
                            'LJ.XMLRPC.friendof',{
                            'username' => $lj_config->{'user'}->[0],
                            'authmethod' => 'clear',
                            'password' => $lj_config->{'password'}->[0]}
                            #'auth_challenge' => $challenge, 
                	    #'auth_response'  => $response}
                            )->result;
    return undef() unless defined $res;
    my @friends;
    foreach my $friend (@{$res->{'friendofs'}}) {
         push @friends, $friend->{'username'} unless (defined($friend->{'type'}) or defined($friend->{'status'})); 
    }
    sleep $lj_config->{'sleep'}->[0];
    return @friends;
}

#
# add friend
#
sub add_friend($$)
{
    my ($lj_config, $toadd) = @_;
    my $client = XMLRPC::Lite->proxy($lj_config->{'xmlrpc_interface'}->[0]); 
    #my $challenge = $client->call("LJ.XMLRPC.getchallenge")->result->{'challenge'}; 
    #my $response = md5_hex($challenge . md5_hex($lj_config->{'password'}->[0]));
    my $res = $client->call(
                            'LJ.XMLRPC.editfriends',{
                            'username' => $lj_config->{'user'}->[0],
                            'authmethod' => 'clear',
                            'password' => $lj_config->{'password'}->[0],
                            'add' => [{username => $toadd},]}
                            #'auth_challenge' => $challenge, 
                	    #'auth_response'  => $response}
                            )->result;
    sleep $lj_config->{'sleep'}->[0];
    return defined $res;
}

#
# delete friend
#
sub delete_friend($$)
{
    my ($lj_config, $tokill) = @_;
    my $client = XMLRPC::Lite->proxy($lj_config->{'xmlrpc_interface'}->[0]); 
   # my $challenge = $client->call("LJ.XMLRPC.getchallenge")->result->{'challenge'}; 
   # my $response = md5_hex($challenge . md5_hex($lj_config->{'password'}->[0]));
    my $res = $client->call(
                            'LJ.XMLRPC.editfriends',{
                            'username' => $lj_config->{'user'}->[0],
                            'authmethod' => 'clear',
                            'password' => $lj_config->{'password'}->[0],
                            'delete' => [$tokill,]}
                            #'auth_challenge' => $challenge, 
                	    #'auth_response'  => $response}
                            )->result;
    #print Dumper($res);
    sleep $lj_config->{'sleep'}->[0];
    return defined $res;
}

#
# get last post date - returns date in seconds of last update
#
sub get_last_post_date($)
{
    my ($source) = @_;
    my $page_src =  LWP::Simple::get("http://$source.livejournal.com/profile") or return undef();
    #sleep 2;
    my $date_str;
    return undef() unless ($page_src =~ /last\ updated\ <span\ class='tooltip'\ title="[a-zA-Z0-9\ ]+">([0-9]{4}-[0-9]{2}-[0-9]{2})<\/span>/i);
    $date_str = $1;
    #print "$source => date str is '$date_str'\n";
    my ($year, $month, $mday) = $date_str =~ /([0-9]{4})-([0-9]{2})-([0-9]{2})/;
    print $year, $month, $mday;
    return undef unless defined $month;
    my $date = timegm(0, 0, 0, $mday, $month - 1, $year);
    return $date;
    #last updated <span class='tooltip' title="2 minutes ago">2009-11-01</span>
}

1;
