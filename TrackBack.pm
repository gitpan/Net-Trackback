# Copyright (c) 2003 Timothy Appnel
# http://tima.mplode.com/
# This code is released under the Artistic License.
#
# Net::TrackBack - A modularized implementation of core TrackBack 1x functionality.
#

package Net::TrackBack;

use strict;

use vars qw( $VERSION );
$VERSION = '0.21';

sub new { 
	my $class = shift;
	my $self = bless {}, $class;
}

sub receive_ping { # $id (integer), $ping (HASH Ref), $callback (subroutine reference)
	my $self = shift;
	my $id = shift;
	my $ping = shift; 
	my $callback = shift;

	$self->_init_message;
    $id =~ tr/a-zA-Z0-9/_/cs;
	return $self->_set_message(1,"No TrackBack ID (tb_id)",1) unless $id;
    my $i = { map { $_ => scalar $ping->{$_} } qw(title excerpt url blog_name) };
	$i->{id}=$id; # store "munged" id
    $i->{title} ||= $i->{url};
    $i->{timestamp} = time;
	return $self->_set_message(1,"No URL (url)",1) unless $i->{url};
	my $msg = $callback->($i); # Callback returns a string if an error occured and a false value if successful. Counter intuituve?
	return $msg ? $self->_set_message(1,$msg,1) : $self->_set_message(0,qq(Ping of $id successful received from $i->{url}),1);
}

sub send_ping { # ping_data (HASH Ref)
	my $self = shift;
	my $ping = shift;
	
	$self->_init_message;
    require LWP::UserAgent;
    my $ua = LWP::UserAgent->new;
    $ua->agent("Net::TrackBack/$VERSION");
    my @qs = map $_ . '=' . _encode_url($ping->{$_} || ''),
             qw( title url excerpt blog_name );
    my $ping_url = $ping->{ping_url} or return $self->_set_message(1,"No ping URL");
    my $req;
    if ($ping_url =~ /\?/) {
        $req = HTTP::Request->new(GET => $ping_url . '&' . join('&', @qs));
    } else {
        $req = HTTP::Request->new(POST => $ping_url);
        $req->content_type('application/x-www-form-urlencoded');
        $req->content(join('&', @qs));
    }
    my $res = $ua->request($req);
    return $self->_set_message(1,"HTTP error: " . $res->status_line) unless $res->is_success;
	my($e, $msg) = $res->content =~ m!<error>(\d+).*<message>(.+?)</message>!s;
    return $e ? $self->_set_message(1,"Error: $msg"):$self->_set_message(0,"Ping to $ping_url sent successfully.");
}

sub discover { # url (string)
    my $self = shift;
    my $url = shift;
	
	$self->_init_message;
    require LWP::UserAgent;
    my $ua = LWP::UserAgent->new;
    $ua->agent("Net::TrackBack/$VERSION");  
    $ua->parse_head(0);
    $ua->timeout(15);
    my $req = HTTP::Request->new(GET => $url);
    my $res = $ua->request($req);
    return $self->_set_message(1,"HTTP error: " . $res->status_line) unless $res->is_success;
    my $c = $res->content;
    (my $url_no_anchor = $url) =~ s/#.*$//;
	my @pings;
	# Theoretically this is bad namespace form and eventually should be fixed.
	# If you stick to the standard prefixes you're fine.
    while ($c =~ m!(<rdf:RDF.*?</rdf:RDF>)!sg) {
        my $rdf = $1;
        my($perm_url) = $rdf =~ m!dc:identifier="([^"]+)"!;  
        next unless $perm_url eq $url || $perm_url eq $url_no_anchor;
        if ($rdf =~ m!trackback:ping="([^"]+)"!) {
			push(@pings, $1);
        } elsif ($rdf =~ m!about="([^"]+)"!) {
			push(@pings, $1);
        }
    }
	@pings ?
		$self->_set_message(0,qq(TrackBack information has been retreived from $url)):
		$self->_set_message(1,qq(TrackBack information could not be found in $url));
	return @pings
}	

#### external utility methods

sub get_tb_id { # Utility method for use with CGI.pm;
	my $self = shift;
	my $q =shift; # CGI.pm reference
    my $tb_id = $q->param('tb_id');
    unless ($tb_id) {
        if (my $pi = $q->path_info()) {
            ($tb_id = $pi) =~ s!^/!!;
        }
    }
    return $tb_id;
}

sub is_success { return (! $_[0]->{__msg}->{code}) }
sub is_error { return $_[0]->{__msg}->{code} }
sub message { $_[0]->{__msg}->{msg} }


#### internal utility methods

sub _init_message { shift->{__msg} = undef; }

sub _set_message { 
	$_[0]->{__msg}->{code}=$_[1];
	$_[0]->{__msg}->{msg}=$_[2]; 
	_generate_response($_[1],$_[2]) if $_[3]; 
}

sub _generate_response {     
	print "Content-Type: text/xml\n\n";
    print qq(<?xml version="1.0" encoding="iso-8859-1"?>\n<response>\n);
    printf qq(<error>$_[0]</error>\n%s\n), _xml('message', $_[1]);
    print "</response>\n";
}

my(%Map, $RE);
BEGIN {
    %Map = ('&' => '&amp;', '"' => '&quot;', '<' => '&lt;', '>' => '&gt;', "'" => '&apos;');
    $RE = join '|', keys %Map;
}
sub _xml {
    (my $s = defined $_[1] ? $_[1] : '') =~ s!($RE)!$Map{$1}!g;
    "<$_[0]>$s</$_[0]>\n";
}

sub _encode_url {
    (my $str = $_[0]) =~ s!([^a-zA-Z0-9_.-])!uc sprintf "%%%02x", ord($1)!eg;
    return $str;
}

1;

__END__

=head1 NAME

Net::TrackBack - A modularized implementation of core TrackBack 1x functionality.

=head1 SYNOPSIS

	<!-- a sample receive ping -->
	use Net::TrackBack;
	use CGI qw( :cgi-lib :standard );

	my $q = new CGI;
	my $p = new Net::TrackBack;

	my $foo = $q->Vars;
	$p->receive_ping($p->get_tb_id($q), $foo, \&dump2warn );
	
	sub dump2warn {
		my $data=shift;
		foreach (keys %{ $data }) {	warn "$_ " . $data->{$_} }
	}
	
	<!-- a sample discover pings -->
	use Net::TrackBack;

	my $url = 'http://www.mplode.com/tima/archives/000190.html';
	$p=new Net::TrackBack;
	foreach ($p->discover($url)) { print "$_\n"; }
	if ($p->is_success) { print "A SUCCESS!\n"; }
	elsif ($p->is_error) { print "A FAILURE.\n". $p->message ."\n"; }

	<!-- a sample send ping -->
	use Net::TrackBack;

	$data{ping_url}='http://your/test/trackback.cgi/2ping';
	$data{title}='foo title!';
	$data{url}='http://www.foo.com/tima/';
	$data{excerpt}='foo is the word.';
	$data{blog_name}='Net::TrackBack';

	$p=new Net::TrackBack;
	print qq(Send Ping: $data{url})."\n";
	$p->send_ping(\%data);
	if ($p->is_success) { print "SUCCESS!\n" . $p->message ."\n"; }


=head1 DESCRIPTION

This is a fairly rapid "OO modularization" of the TrackBack functionality found in the TrackBack reference 
implementation and specification. It removes the display and management features found in the reference 
implementation in addition to its reliance on CGI.pm. I take no credit for the genius of TrackBack. Quite a
bit of this modules code was derived from the Standalone TrackBack Implementation. My 
motivation in developing this module is to make experimentation and implementation of TrackBack functions 
a bit easier. 

I've done a fair amount of testing of this module myself, but for now this module should be considered ALPHA 
software. In otherwords, the interface I<may> change based on the feedback and usage patterns that emerge 
once this module circulates for a bit.

Your feedback and suggestions are greatly appreciated. There is still a lot of work to be done. This module
is far from completed. See the TO DO section for some brief thoughts.

This modules requires the L<LWP> package.

=head1 METHODS

The following methods are available:

=over 4

=item * new

Constructor for Net::TrackBack. Returns a reference to a Net::TrackBack object.

=item * $p->receive_ping($tb_id,%data_in,\&code_ref)

Processes a hash of data received for a TrackBack ID (identified by $tb_id) and, after some standardized processing 
passes the data to the routine referenced in code_ref for further processing -- saving the disk, email etc.

=item * $p->send_ping(%data_out)

Takes a hash of elements as defined in the trackBack specification and pings the resource specified in the ping_url element.

=item * $p->discover($url)

Routine that gets a web page specified by $url and extracts all TrackBack pings found. The pings are returned 
in a simple array.

=item * $p->is_success()

Returns a boolen according to the success of the last operation.

=item * $p->is_error()

Returns a boolen according to the failure of the last operation.

=item * $p->message()

Returns a human-readable message for the last operation.

=item * $p->get_tb_id($CGIobj)

A utility method for those working with CGI.pm. Takes a reference to CGI.pm and extracts the 
TrackBack ping ID from the incoming request.

=back

=head1 SEE ALSO

L<LWP>, L<http://www.movabletype.org/docs/mttrackback.html>

=head1 TO DO AND ISSUE

=over 4

=item * C<discover> should probably return an array of hashes.

=item * C<receive_ping> does not handle namespaces properly. You're OK if you stick with the standard prefixes.

=item * Does not support extended Dublin core elements such as &lt;dc:subject&gt; and so on.

=item * Implement TrackBack threading feature?

=back

=head1 LICENSE

The software is released under the Artistic License. The terms of the Artistic License are described at http://www.perl.com/language/misc/Artistic.html.

=head1 AUTHOR & COPYRIGHT

Except where otherwise noted, Net::TrackBack is Copyright 2003, Timothy Appnel, tima@mplode.com. All rights reserved.

=cut