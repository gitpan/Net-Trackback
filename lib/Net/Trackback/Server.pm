# Copyright (c) 2003-4 Timothy Appnel
# http://www.timaoutloud.org/
# This code is released under the Artistic License.
#
# Net::Trackback::Server - a super/static class for implementing
# Trackback server functionality.
# 

package Net::Trackback::Server;

use strict;

use Net::Trackback;
use Net::Trackback::Ping;
use Net::Trackback::Message;

sub receive_ping { Net::Trackback::Ping->parse($_[1]); }

sub send_success { 
    my $msg = Net::Trackback::Message->new( {code=>0, message=>$_[1]} );
    print "Content-Type: text/xml\n\n".$msg->to_xml;
}

sub send_error { 
    my $msg = Net::Trackback::Message->new( {code=>1, message=>$_[1]} );
    print "Content-Type: text/xml\n\n".$msg->to_xml;
}

1;

__END__

=begin

=head1 NAME

Net::Trackback::Server - a super/static class for implementing
Trackback server functionality.

=head1 METHODS

=item Net::Trackback::Server->receive_ping($CGI)

Currently just an alias for Net::Trackback::Ping->parse.

=item Net::Trackback::Server->send_success($string)

Sends a success message (code 0) including the necessary 
Content-Type header and the supplied string parameter as 
its body.

=item Net::Trackback::Server->send_error($string)

Sends an error message (code 1) including the necessary 
Content-Type header and the supplied string parameter as 
its body.

=head1 TO DO

=item Way of sending an error message with a code other then 1.

=item More functionalty? (Need feedback.)

=head1 AUTHOR & COPYRIGHT

Please see the Net::Trackback manpage for author, copyright, and 
license information.

=cut

=end