use strict;
use warnings;

use Test::More;

use_ok('OvhApi');

subtest '_getTarget' => sub {
    is(OvhApi::_getTarget(OvhApi::OVH_API_EU(), '/me'), 'https://eu.api.ovh.com/1.0/me');
    is(OvhApi::_getTarget(OvhApi::OVH_API_EU(), '/v1/me'), 'https://eu.api.ovh.com/v1/me');
    is(OvhApi::_getTarget(OvhApi::OVH_API_EU(), '/v2/me'), 'https://eu.api.ovh.com/v2/me');

    is(OvhApi::_getTarget(OvhApi::OVH_API_EU(), 'me'), 'https://eu.api.ovh.com/1.0/me');
    is(OvhApi::_getTarget(OvhApi::OVH_API_EU(), 'v1/me'), 'https://eu.api.ovh.com/v1/me');
    is(OvhApi::_getTarget(OvhApi::OVH_API_EU(), 'v2/me'), 'https://eu.api.ovh.com/v2/me');
};

done_testing;
