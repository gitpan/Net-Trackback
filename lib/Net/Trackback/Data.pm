# Copyright (c) 2003-4 Timothy Appnel
# http://www.timaoutloud.org/
# This code is released under the Artistic License.
#
# Net::Trackback::Data - an object representing Trackback data to a
# pingable resource.
# 

package Net::Trackback::Data;

use strict;

my %fields;
map { $fields{$_}=1 } 
    qw( title identifier subject description creator date source 
        publisher contributor type format language relation 
        coverage rights );

# Because ping is not in the dublin core element set
# namespace we make this exception and manually code it.
sub ping {
        $_[0]->{__stash}->{ping} = $_[1] if $_[1];
        $_[0]->{__stash}->{ping};
}

sub new { 
    my $self = bless {}, $_[0];
    # Should we filter out unknown fields?
    $self->{__stash} = $_[1] if $_[1];
    $self;
}

sub parse {
    my $class = shift;
    my $url = shift;
    my $rdf = shift;
    my $target = $class->new();
    # Eventually insert XML::Parser option here.
    my ($perm_url) = $rdf =~ m!dc:identifier="([^"]+)"!;
    (my $url_no_anchor = $url) =~ s/#.*$//;
    next unless $perm_url eq $url || $perm_url eq $url_no_anchor;
    my $self = $class->new();
    # Theoretically this is bad namespace form and eventually 
    # should be fixed. If you stick to the standard prefixes 
    # you're fine.
    if ( $rdf =~ m!trackback:ping="([^"]+)"! ||
            $rdf =~ m!about="([^"]+)"! ) {
        $self->{__stash}->{ping}=$1;
        while ( $rdf=~m!dc:(\w+)="([^"]+)"!g ) {
            $self->$1( Net::Trackback->decode_xml($2) );
        }
    }
    $self;
}

sub to_hash { %{ $_[0]->{__stash} } }

sub to_rdf {
    my $self = shift;
    my $stash = $self->{__stash};
    my $indent = '    ';
    my $aterm = "\"\n";
    my $a = $indent.'rdf:about="'.$stash->{identifier}.$aterm;
    $a .= $indent.'trackback:ping="'.$stash->{ping}.$aterm if $stash->{ping}; 
    foreach (keys %fields) {
        if ($stash->{$_}) {
            my $val = Net::Trackback->encode_xml($stash->{$_});
            $a .= "${indent}dc:$_=\"$val$aterm";
        }
    }
    my $rdf = <<RDF;
<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
         xmlns:Trackback="http://madskills.com/public/xml/rss/module/Trackback/"
         xmlns:dc="http://purl.org/dc/elements/1.1/">
<rdf:Description
$a />
</rdf:RDF>
RDF
    $rdf;
}

DESTROY { }

use vars qw( $AUTOLOAD );
sub AUTOLOAD {
    (my $var = $AUTOLOAD) =~ s!.+::!!;
    no strict 'refs';
    die "$var is not a recognized method."
        unless ( $fields{$var} );
    *$AUTOLOAD = sub {
        $_[0]->{__stash}->{$var} = $_[1] if $_[1];
        $_[0]->{__stash}->{$var};
    };
    goto &$AUTOLOAD;
}

1;

__END__

=begin

=head1 NAME

Net::Trackback::Data - an object representing Trackback data to a
pingable resource.

=head1 SYNOPSIS

 use Net::Trackback::Data;
 my $data = Net::Trackback::Data->new();
 $data->url('http://www.timaoutloud.org/archives/000206.html');
 $data->ping('http://www.timaoutloud.org/cgi/mt/mt-tb.cgi/105');
 $data->title('The Next Generation of TrackBack: A Proposal');
 $data->description('I thought it would be helpful to draft some 
    suggestions for consideration for the next generation (NG) 
    of the interface.');
 print $data->to_rdf."\n";

=head1 METHODS

=item Net::Trackback::Data->new([$hashref])

Constuctor method. It will initialize the object if passed a 
hash reference. Recognized keys are title, identifier, subject, 
description, creator, date, source, publisher, contributor, type, 
format, language, relation, coverage, rights and ping. (These are 
all the Dublin Core Metadata Element Set except for ping of 
course.) These keys correspond to the methods like named methods. 

=item Net::Trackback::Data->parse($rdf)

A method that parses (albeit crude using regex) Trackback data from
a string of RDF and returns a data object. In the event a bad or 
incomplete data has been passed in the method will return the 
appropriate Trackback error message as a L<Net::Trackback::Message>
object. One required parameter, a string containing RDF. See the list 
of recognized keys in the L<new> method.

B<NOTE:> This module does not use a XML or RDF parser therefore
namespaces are not handled properly. The prefixes are assumed to be
fixed to a specific URI. This is consistent with the reference 
implementation standalone Trackback code in which the module was 
originally based.

=item $data->identifier([$url])

Accessor to the resource's URL that can be pinged. A value is 
required for Trackback clients to process the data. If an optional
parameter is passed in the value is set.

=item $data->ping([$url])

Accessor to the ping URL of the resource. A value is required for 
Trackback clients to process the data. If an optional parameter is 
passed in the value is set.

=item $data->title([$title])

=item $data->subject([$subject])

=item $data->description([$description])

=item $data->creator([$creator])

=item $data->date([$date])

=item $data->source([$source])

=item $data->publisher([$publisher])

=item $data->contributor([$contributor])

=item $data->type([$type])

=item $data->format([$format])

=item $data->language([$language])

=item $data->relation([$relation])

=item $data->coverage([$coverage])

=item $data->rights([$rights])

Accessor methods to the remaining Dublin Core Metadata Element Set.
If an optional parameter is passed in the value is set. All are 
optional for Trackback client discovery. Use as needed. (Title and 
description are highly recommended by this modules author.)

=item $data->to_hash

Returns a hash of the object's current state.

=item $data->to_rdf

Returns an RDF representation of the object metadata that can 
be inserted into an (X)HTML page for discovery by Trackback 
clients.

=head1 SEE ALSO

Dublin Core Metadata Element Set, Version 1.1: Reference Description 
L<http://dublincore.org/documents/dces/>

TrackBack Module for RSS 1.0/2.0: 
L<http://madskills.com/public/xml/rss/module/trackback/>

=head1 AUTHOR & COPYRIGHT

Please see the Net::Trackback manpage for author, copyright, and 
license information.

=cut

=end