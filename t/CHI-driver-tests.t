#!perl -w
use strict;
use warnings;
use CHI::Driver::Redis::t::CHIDriverTests;

use Test::More;

BEGIN {
    defined($ENV{CHI_REDIS_SERVER}) or plan skip_all => 'Must set CHI_REDIS_SERVER environment variable';
}

CHI::Driver::Redis::t::CHIDriverTests->runtests;