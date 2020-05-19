perl-ovh
========

Perl wrapper around OVH's APIs. Handles all the hard work including credential creation and requests signing.

## Synopsis

```perl
#!/usr/bin/env perl
use strict;
use warnings;

use OvhApi;

my $ApiOvh = OvhApi->new(
    timeout             => 10,
);

my $identity = $ApiOvh->get(path => "/me");
if (!$identity)
{
    printf("Failed to retrieve identity: %s\n", $identity);
    return 0;
}
$identity = $identity->content();

printf("Welcome %s\n", $identity->{'firstname'});
```

## Installation

```
perl Makefile.PL
make
make test
make install
```

## Register your app

OVH's API, like most modern APIs is designed to authenticate both an application and
a user, without requiring the user to provide a password. Your application will be
identified by its "application secret" and "application key" tokens.

Hence, to use the API, you must first register your application and then ask your
user to authenticate on a specific URL. Once authenticated, you'll have a valid
"consumer key" which will grant your application on specific APIs.

The user may choose the validity period of its authorization. The default period is
24h. He may also revoke an authorization at any time. Hence, your application should
be prepared to receive 403 HTTP errors and prompt the user to re-authenticated.

This process is detailed in the following section. Alternatively, you may only need
to build an application for a single user. In this case you may generate all
credentials at once. See below.

### Use the API on behalf of a user

Visit [https://eu.api.ovh.com/createApp](https://eu.api.ovh.com/createApp) and create your app
You'll get an application key and an application secret. To use the API you'll need a consumer key.

The consumer key has two types of restriction:

* path: eg. only the ```GET``` method on ```/me```
* time: eg. expire in 1 day


Then, get a consumer key.

### Use the API for a single user

Alternatively, you may generate all creadentials at once, including the consumer key. You will
typically want to do this when writing automation scripts for a single projects.

If this case, you may want to directly go to https://eu.api.ovh.com/createToken/ to generate
the 3 tokens at once.

## Configuration

The straightforward way to use OVH's API keys is to embed them directly in the
application code. While this is very convenient, it lacks of elegance and
flexibility. You might also need to add your scripts into some source control systems,
and adding credentials into source control is not the best way to manage your credentials.

`perl-ovh` will look for a configuration file of the form:

```ini
[default]
; general configuration: default endpoint
endpoint=ovh-eu

[ovh-eu]
; configuration specific to 'ovh-eu' endpoint
application_key=my_app_key
application_secret=my_application_secret
consumer_key=my_consumer_key
```

Depending on the API you want to use, you may set the ``endpoint`` to:

* ``ovh-eu`` for OVH Europe API
* ``ovh-us`` for OVH US API
* ``ovh-ca`` for OVH Canada API
* ``soyoustart-eu`` for So you Start Europe API
* ``soyoustart-ca`` for So you Start Canada API
* ``kimsufi-eu`` for Kimsufi Europe API
* ``kimsufi-ca`` for Kimsufi Canada API

The client will successively attempt to locate this configuration file in

1. Current working directory: ``./ovh.conf``
2. Current user's home directory ``~/.ovh.conf``
3. System wide configuration ``/etc/ovh.conf``

This lookup mechanism makes it easy to overload credentials for a specific
project or user.


## Usage

```perl
#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;

use OvhApi;

sub main
{
    my $ApiOvh = OvhApi->new(
        timeout             => 10,
    );

    if (not $ApiOvh->{consumerKey})
    {
        my $validation = $ApiOvh->requestCredentials(
            accessRules => [
                {
                    method  => "ALL",
                    path    => "/hosting/web*",
                },
                {
                    method  => "GET",
                    path    => "/me",
                },
            ]
        );
        if (not $validation)
        {
            printf("Failed to request new credentials: %s\n", $validation);
            return 0;
        }

        $validation = $validation->content();
        printf("Please visit %s to authenticate,\nand press Enter to continue...", $validation->{'validationUrl'});
        <STDIN> // die "Abort.\n";
        $ApiOvh->{consumerKey} = $validation->{'consumerKey'};
        printf("Your 'consumerKey' is '%s', you can save it to use it next time you want to use this script!\n", $ApiOvh->{'consumerKey'});
    }

    my $identity = $ApiOvh->get(path => "/me");
    if (!$identity)
    {
        printf("Failed to retrieve identity: %s\n", $identity);
        return 0;
    }
    $identity = $identity->content();

    printf("Welcome %s\n", $identity->{'firstname'});

    print("Listing all web hosting products...\n");
    my $hostingWebList = $ApiOvh->get(
        path => '/hosting/web',
    );
    if (not $hostingWebList)
    {
        printf("Error: %s\n", $hostingWebList);
        return 0;
    }
    $hostingWebList = $hostingWebList->content;

    if (not @$hostingWebList)
    {
        print("You don't have any web hosting on your account!\n");
        return 0;
    }

    print("Available web hosting:\n");
    foreach my $hostingWeb (@$hostingWebList)
    {
        printf("- %s\n", $hostingWeb);
    }

    printf("\nRenaming %s\nEnter a new name: ", $hostingWebList->[0]);
    my $newName = <STDIN> // die "Abort.\n";
    chomp $newName;

    my $renamingOperation = $ApiOvh->put(
        path => "/hosting/web/".$hostingWebList->[0],
        body => {
            displayName => $newName,
        },
    );
    if (not $renamingOperation)
    {
        printf("Error while renaming: %s\n", $renamingOperation);
        return 0;
    }
    print("Renamed successfully!\n");
}

main();
```


## Hacking

This wrapper uses standard Perl tools, so you should feel at home with it.

You've developed a new cool feature ? Fixed an annoying bug ? We'd be happy
to hear from you ! See [CONTRIBUTING.md](https://github.com/ovh/perl-ovh/blob/master/CONTRIBUTING.md)
for more informations

## Supported APIs

### OVH Europe

- **Documentation**: https://eu.api.ovh.com/
- **Community support**: api-subscribe@ml.ovh.net
- **Console**: https://eu.api.ovh.com/console
- **Create application credentials**: https://eu.api.ovh.com/createApp/
- **Create script credentials** (all keys at once): https://eu.api.ovh.com/createToken/

### OVH US

- **Documentation**: https://api.us.ovhcloud.com/
- **Console**: https://api.us.ovhcloud.com/console/
- **Create application credentials**: https://api.us.ovhcloud.com/createApp/
- **Create script credentials** (all keys at once): https://api.us.ovhcloud.com/createToken/

### OVH Canada

- **Documentation**: https://ca.api.ovh.com/
- **Community support**: api-subscribe@ml.ovh.net
- **Console**: https://ca.api.ovh.com/console
- **Create application credentials**: https://ca.api.ovh.com/createApp/
- **Create script credentials** (all keys at once): https://ca.api.ovh.com/createToken/

### So you Start Europe

- **Documentation**: https://eu.api.soyoustart.com/
- **Community support**: api-subscribe@ml.ovh.net
- **Console**: https://eu.api.soyoustart.com/console/
- **Create application credentials**: https://eu.api.soyoustart.com/createApp/
- **Create script credentials** (all keys at once): https://eu.api.soyoustart.com/createToken/

### So you Start Canada

- **Documentation**: https://ca.api.soyoustart.com/
- **Community support**: api-subscribe@ml.ovh.net
- **Console**: https://ca.api.soyoustart.com/console/
- **Create application credentials**: https://ca.api.soyoustart.com/createApp/
- **Create script credentials** (all keys at once): https://ca.api.soyoustart.com/createToken/

### Kimsufi Europe

- **Documentation**: https://eu.api.kimsufi.com/
- **Community support**: api-subscribe@ml.ovh.net
- **Console**: https://eu.api.kimsufi.com/console/
- **Create application credentials**: https://eu.api.kimsufi.com/createApp/
- **Create script credentials** (all keys at once): https://eu.api.kimsufi.com/createToken/

### Kimsufi Canada

- **Documentation**: https://ca.api.kimsufi.com/
- **Community support**: api-subscribe@ml.ovh.net
- **Console**: https://ca.api.kimsufi.com/console/
- **Create application credentials**: https://ca.api.kimsufi.com/createApp/
- **Create script credentials** (all keys at once): https://ca.api.kimsufi.com/createToken/

## License

3-Clause BSD

