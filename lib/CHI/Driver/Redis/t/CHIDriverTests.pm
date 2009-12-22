package CHI::Driver::Redis::t::CHIDriverTests;
use strict;
use warnings;
use CHI::Test;
use base qw(CHI::t::Driver);

sub testing_driver_class { 'CHI::Driver::Redis' }

sub new_cache_options {
    my $self = shift;

    return (
        $self->SUPER::new_cache_options(),
        driver_class => 'CHI::Driver::Redis',
        server => '127.0.0.1:6379',
    );
}

sub clear_redis : Test(setup) {
    my ($self) = @_;

    my $cache = $self->new_cache;
    $cache->_verify_redis_connection;
    $cache->redis->flushall;
}

1;