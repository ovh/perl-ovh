perl-ovh
========

Perl wrapper around OVH's APIs. Handles all the hard work including credential creation and requests signing.

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

