# Copyright (c) 2003-4 Timothy Appnel
# http://www.timaoutloud.org/
# This code is released under the Artistic License.
#
# Net::Trackback::Client - a class for implementing Trackback client 
# functionality. 
# 

package Net::Trackback::Client;

use strict;

use Net::Trackback;
use Net::Trackback::Data;
use Net::Trackback::Message;

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    $self->{__timeout} = 15;
    $self;
}

sub discover {
    my $self = shift;
    my $url  = shift;
    require LWP::UserAgent;
    my $ua = LWP::UserAgent->new;
    $ua->agent("Net::Trackback/$Net::Trackback::VERSION");
    $ua->parse_head(0);
    $ua->timeout($self->{__timeout});
    my $req = HTTP::Request->new( GET => $url );
    my $res = $ua->request($req);
    return Net::Trackback::Message->new( {
        code=>$res->code, message=>$res->message } )
            unless $res->is_success;
    my $c = $res->content;
    my @data;
    # Theoretically this is bad namespace form and eventually should 
    # be fixed. If you stick to the standard prefixes you're fine.
    while ( $c =~ m!(<rdf:RDF.*?</rdf:RDF>)!sg ) {
        if (my $tb = Net::Trackback::Data->parse($url,$1)) {
            push( @data, $tb ); 
        }
    }
    \@data;
}

sub send_ping {
    my $self = shift;
    my $ping = shift;
    require LWP::UserAgent;
    my $ua = LWP::UserAgent->new;
    $ua->agent("Net::Trackback/$Net::Trackback::VERSION");
    $ua->timeout($self->{__timeout});
    my $ping_url = $ping->ping_url or
        return Net::Trackback::Message->new( { code=>1, message=>'No ping URL' } );
    my $req;
    $ping->timestamp(time);
    if ( $ping_url =~ /\?/ ) {
        $req = HTTP::Request->new( GET=>join('&', $ping_url, $ping->to_urlencoded) );
    } else {
        $req = HTTP::Request->new( POST => $ping_url );
        $req->content_type('application/x-www-form-urlencoded');
        $req->content( $ping->to_urlencoded );
    }
    my $res = $ua->request($req);
    return Net::Trackback::Message->new( {
        code=>$res->code, message=>$res->message } )
            unless $res->is_success;
    Net::Trackback::Message->parse( $res->content );
}

sub timeout { $_[0]->{__timeout} = $_[1] if $_[1]; $_[0]->{__timeout}; }

1;

__END__

=begin

=head1 NAME

Net::Trackback::Client - a class for implementing Trackback client 
functionality. 

=head1 SYNOPSIS

 use Net::Trackback::Client;
 my $client = Net::Trackback::Client->new();
 my $url ='http://www.foo.org/foo.html';
 my $data = $client->discover($url);
 if (Net::Trackback->is_message($data)) {
    print $data->to_xml;
 } else {
    require Net::Trackback::Ping;
    my $p = {
        ping_url=>'http://www.foo.org/cgi/mt-tb.cgi/40',
        url=>'http://www.timaoutloud.org/archives/000206.html',
        title=>'The Next Generation of TrackBack: A Proposal',
        description=>'I thought it would be helpful to draft some 
            suggestions for consideration for the next generation (NG) 
            of the interface.'
    };
 my $ping = Net::Trackback::Ping->new($p);
 my $msg = $client->send_ping($ping);
 print $msg->to_xml;

=head1 METHODS

=item Net::Trackback::Client->new

Constructor method. Returns a Trackback client instance.

=item $client->discover($url)

A method that fetches the resource and searches for Trackback ping
data. If the given resource can not be retreived, a 
L<Net::Trackback::Message> object is returned with the HTTP error
code and message. (A liberty this module takes from the Trackback 
specification.) Returns a reference to an array of 
L<Net::Trackback::Data>  objects. If the resource is retreived 
and nothing was found returns C<undef>.

=item $client->send_ping($ping)

Executes a ping according to the L<Net::Trackback::Ping> object 
passed in and returns a L<Net::Trackback::Message> object with the 
results,

=item $client->timeout([$seconds])

An accessor to the LWP agent timeout in seconds. Default is 15 
seconds. If an optional parameter is passed in the value is set.

=head1 AUTHOR & COPYRIGHT

Please see the Net::Trackback manpage for author, copyright, and 
license information.

=cut

=end