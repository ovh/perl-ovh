package OvhApi;

use strict;
use warnings;

use constant VERSION => '1.1';

use OvhApi::Answer;

use Carp            qw{ carp croak };
use List::Util      'first';
use LWP::UserAgent  ();
use JSON            ();
use Digest::SHA     'sha1_hex';


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Class constants

use constant {
    OVH_API_EU => 'https://eu.api.ovh.com/1.0',
    OVH_API_CA => 'https://ca.api.ovh.com/1.0',
    OVH_API_US => 'https://api.us.ovhcloud.com/1.0',
    SOYOUSTART_API_EU => 'https://eu.api.soyoustart.com/1.0',
    SOYOUSTART_API_CA => 'https://ca.api.soyoustart.com/1.0',
    KIMSUFI_API_EU => 'https://eu.api.kimsufi.com/1.0',
    KIMSUFI_API_CA => 'https://ca.api.kimsufi.com/1.0',
};

# End - Class constants
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Class variables

my $UserAgent = LWP::UserAgent->new(timeout => 10);
my $Json      = JSON->new->allow_nonref;

my @accessRuleMethods = qw{ GET POST PUT DELETE };
my %configKey = (
    'ovh-eu' => OVH_API_EU,
    'ovh-ca' => OVH_API_CA,
    'ovh-us' => OVH_API_US,
    'soyoustart-eu' => SOYOUSTART_API_EU,
    'soyoustart-ca' => SOYOUSTART_API_CA,
    'kimsufi-eu' => KIMSUFI_API_EU,
    'kimsufi-ca' => KIMSUFI_API_CA,
);

my %reverseConfigKey = reverse %configKey;

my %configKeySnakeToCamel = (
    'applicationKey'    => 'application_key',
    'applicationSecret' => 'application_secret',
    'consumerKey'       => 'consumer_key',
);

# End - Class variables
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Class methods

sub new
{
    my @keys = qw{ applicationKey applicationSecret consumerKey timeout };

    my ($class, %params) = @_;

    my $configuration = retrieveConfiguration();

    if ($params{'type'})
    {
        if (not exists $reverseConfigKey{$params{'type'}})
        {
            carp 'Invalid type parameter: defaulting to OVH_API_EU';
            $params{'type'} = OVH_API_EU;
        }
    }

    if ($configuration)
    {
        my $endpoint;
        if ($params{'type'})
        {
            $endpoint = $reverseConfigKey{$params{'type'}};
        }
        elsif(exists $configuration->{default} and exists $configuration->{default}->{endpoint})
        {
            $endpoint = $configuration->{default}->{endpoint};
        }
        if (not $endpoint)
        {
            carp 'Missing default endpoint in ovh.conf: defaulting to ovh-eu';
            $endpoint = 'ovh-eu';
        }
        if (not exists $configKey{$endpoint})
        {
            local $" = ', ';
            my @legalEndpoints = keys %configKey;
            croak "Invalid endpoint value: $endpoint, valid values are @legalEndpoints";
        }

        $params{'type'} = $configKey{$endpoint};
        if ($configuration->{$endpoint})
        {
            foreach my $key (qw( applicationKey applicationSecret consumerKey ))
            {
                if (not $params{$key} and $configuration->{$endpoint}->{$configKeySnakeToCamel{$key}})
                {
                    $params{$key} = $configuration->{$endpoint}->{$configKeySnakeToCamel{$key}};
                }
            }
        }
    }

    if (my @missingParameters = grep { not $params{$_} } qw{ applicationKey applicationSecret })
    {
        local $" = ', ';
        croak "Missing parameter: @missingParameters";
    }

    my $self = {
        _type   => $params{'type'},
    };

    @$self{@keys} = @params{@keys};

    if ($params{'timeout'})
    {
        $class->setRequestTimeout(timeout => $params{'timeout'});
    }

    bless $self, $class;
}

sub setRequestTimeout
{
    my ($class, %params) = @_;

    if ($params{'timeout'} =~ /^\d+$/)
    {
        $UserAgent->timeout($params{'timeout'});
    }
    elsif (exists $params{'timeout'})
    {
        carp "Invalid timeout: $params{'timeout'}";
    }
    else
    {
        carp 'Missing parameter: timeout';
    }
}

sub retrieveConfiguration
{
    my $fh;
    foreach my $filepath ("$ENV{PWD}/ovh.conf", "$ENV{HOME}/.ovh.conf", '/etc/ovh.conf')
    {
        open($fh, '<', $filepath) and last;
        undef $fh;
    }
    $fh or return undef;

    my (%hash, $section, $key, $value);
    while (<$fh>)
    {
        chomp;
        if (/^\s*\[([\w-]+)\].*/)
        {
            $section = $1;
            next;
        }
        if (/^\s*([\w_]+)=([\w_-]+)\s*(;.*)?$/)
        {
            $key = $1;
            $value = $2;
            $hash{$section}{$key} = $value;
        }
    }
    close($fh);
    return \%hash;
}

# End - Class methods
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Instance methods

sub rawCall
{
    my ($self, %params) = @_;

    if (not $params{'path'})
    {
        carp "Missing parameter: path";
        return OvhApi::Answer::->new(response => HTTP::Response->new( 500, "Missing parameter: path", [], '{"message":"Missing parameter: path"}'));
    }
    if (not $params{'method'})
    {
        carp "Missing parameter: method";
        return OvhApi::Answer::->new(response => HTTP::Response->new( 500, "Missing parameter: method", [], '{"message":"Missing parameter: method"}'));
    }
    my $method = lc $params{'method'};
    my $url    = $self->{'_type'} . (substr($params{'path'}, 0, 1) eq '/' ? '' : '/') . $params{'path'};

    my %httpHeaders;

    my $body = '';
    my %content;

    if (defined $params{'body'} and $method ne 'get' and $method ne 'delete')
    {
        $body = $Json->encode($params{'body'});

        $httpHeaders{'Content-type'} = 'application/json';
        $content{'Content'} = $body;
    }

    unless ($params{'noSignature'})
    {
        my $now    = $self->_timeDelta + time;

        if (not $self->{'consumerKey'})
        {
            carp "Performed an authentified call without providing a valid consumerKey";
            return OvhApi::Answer::->new(response => HTTP::Response->new( 500, "Performed an authentified call without providing a valid consumerKey", [], '{"message":"Performed an authentified call without providing a valid consumerKey"}'));
        }

        $httpHeaders{'X-Ovh-Consumer'}      = $self->{'consumerKey'},
        $httpHeaders{'X-Ovh-Timestamp'}     = $now,
        $httpHeaders{'X-Ovh-Signature'}     = '$1$' . sha1_hex(join('+', (
            # Full signature is '$1$' followed by the hex digest of the SHA1 of all these data joined by a + sign
            $self->{'applicationSecret'},   # Application secret
            $self->{'consumerKey'},         # Consumer key
            uc $method,                     # HTTP method (uppercased)
            $url,                           # Full URL
            $body,                          # Full body
            $now,                           # Curent OVH server time
        )));
    }

    $httpHeaders{'X-Ovh-Application'}   = $self->{'applicationKey'};

    return OvhApi::Answer::->new(response => $UserAgent->$method($url, %httpHeaders, %content));
}

sub requestCredentials
{
    my ($self, %params) = @_;

    croak 'Missing parameter: accessRules' unless $params{'accessRules'};
    croak 'Invalid parameter: accessRules' if ref $params{'accessRules'} ne 'ARRAY';

    my @rules = map {
        croak 'Invalid access rule: must be HASH ref' if ref ne 'HASH';

        my %rule = %$_;

        $rule{'method'} = uc $rule{'method'};

        croak 'Access rule must have method and path keys' unless $rule{'method'} and $rule{'path'};
        croak 'Invalid access rule method'                 unless first { $_ eq $rule{'method'} } (@accessRuleMethods, 'ALL');

        if ($rule{'method'} eq 'ALL')
        {
            map { path => $rule{'path'}, method => $_ }, @accessRuleMethods;
        }
        else
        {
            \%rule
        }
    } @{ $params{'accessRules'} };

    return $self->post(path => '/auth/credential/', noSignature => 1, body => { accessRules => \@rules });
}

# Generation of helper subs: simple wrappers to rawCall
# Generate: get(), post(), put(), delete()
{
    no strict 'refs';

    for my $method (qw{ get post put delete })
    {
        *$method = sub { rawCall(@_, 'method', $method ) };
    }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
# Private part

sub _timeDelta
{
    my ($self, %params) = @_;

    unless (defined $self->{'_timeDelta'})
    {
        if (my $ServerTimeResponse = $self->get(path => 'auth/time', noSignature => 1))
        {
            $self->{'_timeDelta'} = ($ServerTimeResponse->content - time);
        }
        else
        {
            return 0;
        }
    }

    return $self->{'_timeDelta'};
}

# End - Instance methods
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


return 42;


__END__

=head1 NAME

OvhApi - Official OVH Perl wrapper upon the OVH RESTful API.

=head1 SYNOPSIS

  use OvhApi;

  my $Api    = OvhApi->new(type => OvhApi::OVH_API_EU, applicationKey => $AK, applicationSecret => $AS, consumerKey => $CK);
  my $Answer = $Api->get(path => '/me');

=head1 DESCRIPTION

This module is an official Perl wrapper that OVH provides in order to offer a simple way to use its RESTful API.
C<OvhApi> handles the authentication layer, and uses C<LWP::UserAgent> in order to run requests.

Answer are retured as instances of L<OvhApi::Answer|OvhApi::Answer>.

=head1 CLASS METHODS

=head2 Constructor

There is only one constructor: C<new>.

Its parameters are:

    Parameter           Mandatory                               Default                 Usage
    ------------        ------------                            ----------              --------
    type                Carp if missing                         OVH_API_EU()            Determine if you'll use european or canadian OVH API (possible values are OVH_API_EU and OVH_API_CA)
    timeout             No                                      10                      Set the timeout LWP::UserAgent will use
    applicationKey      Yes                                     -                       Your application key
    applicationSecret   Yes                                     -                       Your application secret
    consumerKey         Yes, unless for a credential request    -                       Your consumer key

=head2 OVH_API_EU

L<Constant|constant> that points to the root URL of OVH European API.

=head2 OVH_API_CA

L<Constant|constant> that points to the root URL of OVH Canadian API.

=head2 OVH_API_US

L<Constant|constant> that points to the root URL of OVHcloud US API.

=head2 SOYOUSTART_API_EU

L<Constant|constant> that points to the root URL of SoYouStart European API.

=head2 SOYOUSTART_API_CA

L<Constant|constant> that points to the root URL of SoYouStart Canadian API.

=head2 KIMSUFI_API_EU

L<Constant|constant> that points to the root URL of Kimsufi European API.

=head2 KIMSUFI_API_CA

L<Constant|constant> that points to the root URL of Kimsufi Canadian API.

=head2 setRequestTimeout

This method changes the timeout C<LWP::UserAgent> uses. You can set that in L<new|/Constructor> instead.

Its parameters are:

    Parameter           Mandatory
    ------------        ------------
    timeout             Yes

=head1 INSTANCE METHODS

=head2 rawCall

This is the main method of that wrapper. This method will take care of the signature, of the JSON conversion of your data, and of the effective run of the query.

Its parameters are:

    Parameter           Mandatory                               Default                 Usage
    ------------        ------------                            ----------              --------
    path                Yes                                     -                       The API URL you want to request
    method              Yes                                     -                       The HTTP method of the request (GET, POST, PUT, DELETE)
    body                No                                      ''                      The body to send in the query. Will be ignore on a GET
    noSignature         No                                      false                   If set to a true value, no signature will be send

=head2 get

Helper method that wraps a call to:

    rawCall(method => 'get");

All parameters are forwarded to L<rawCall|/rawCall>.

=head2 post

Helper method that wraps a call to:

    rawCall(method => 'post');

All parameters are forwarded to L<rawCall|/rawCall>.

=head2 put

Helper method that wraps a call to:

    rawCall(method => 'put');

All parameters are forwarded to L<rawCall|/rawCall>.

=head2 delete

Helper method that wraps a call to:

    rawCall(method => 'delete');

All parameters are forwarded to L<rawCall|/rawCall>.

=head2 requestCredentials

This method will request a Consumer Key to the API. That credential will need to be validated with the link returned in the answer.

Its parameters are:

    Parameter           Mandatory
    ------------        ------------
    accessRules         Yes

The C<accessRules> parameter is an ARRAY of HASHes. Each hash contains these keys:

=over

=item * method: an HTTP method among GET, POST, PUT and DELETE. ALL is a special values that includes all the methods;

=item * path: a string that represents the URLs the credential will have access to. C<*> can be used as a wildcard. C</*> will allow all URLs, for example.

=back

=head3 Example

    # Giving full access to all services under an account

    my $Api = OvhApi->new(type => OvhApi::OVH_API_EU, applicationKey => $AK, applicationSecret => $AS);
    my $Answer = $Api->requestCredentials(accessRules => [ { method => 'ALL', path => '/*' }]);

    if ($Answer)
    {
        my ($consumerKey, $validationUrl) = @{ $Answer->content}{qw{ consumerKey validationUrl }};

        # $consumerKey contains the newly created Consumer Key
        # $validationUrl contains a link to OVH website in order to login an OVH account and link it to the credential
    }

    # Another case would be giving access to only one object under a path, for example to allow rebooting only a defined server:

    my $Answer = $Api->requestCredentials(accessRules => [ { method => 'POST', path => '/dedicated/server/ns123456789.ovh.net/reboot' }]);

    # It is also possible to allow rebooting any server under the account:

    my $Answer = $Api->requestCredentials(accessRules => [ { method => 'POST', path => '/dedicated/server/*/reboot' }]);

=head1 SEE ALSO

The guts of module are using: C<LWP::UserAgent>, C<JSON>, C<Digest::SHA>.

=head1 COPYRIGHT

Copyright (c) 2013-2020, OVH SAS.
All rights reserved.

This library is distributed under the terms of BSD 3-Clause License, see C<LICENSE>.

=cut

