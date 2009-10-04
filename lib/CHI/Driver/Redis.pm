package CHI::Driver::Redis;
use Moose;

use Redis;
use Try::Tiny;

extends 'CHI::Driver';

has '_redis' => (
    is => 'rw',
    isa => 'Redis'
);

has '_params' => (
    is => 'rw'
);

sub BUILD {
    my ($self, $params) = @_;

    $self->_params($params);
    $self->_redis(
        Redis->new(
            server => $params->{server} || '127.0.0.1:6379',
            debug => $params->{debug} || 0
        )
    );
}

sub fetch {
    my ($self, $key) = @_;

    $self->_verify_redis_connection;

    return $self->_redis->get($self->namespace."||$key");
}

sub fetch_multi_hashref {
    my ($self, $keys) = @_;

    my %kv;
    foreach my $k (@{ $keys }) {
        $kv{$self->namespace."||$k"} = undef;
    }

    my @vals = $self->_redis->mget(keys %kv);

    my $count = 0;
    foreach my $k (@{ $keys }) {
        $kv{$k} = $vals[$count];
        $count++;
    }

    return \%kv;
}

sub get_keys {
    my ($self) = @_;

    return $self->_redis->smembers($self->namespace);
}

sub get_namespaces {
    my ($self) = @_;

    return $self->_redis->smembers('chinamespaces');
}

sub remove {
    my ($self, $key) = @_;

    $self->_verify_redis_connection;

    my $ns = $self->namespace;

    $self->_redis->srem($ns, $key);
    $self->_redis->del("$ns||$key");
}

sub store {
    my ($self, $key, $data, $expires_at, $options) = @_;

    $self->_verify_redis_connection;

    my $ns = $self->namespace;

    my $realkey = "$ns||$key";

    $self->_redis->sadd('chinamespaces', $ns);
    $self->_redis->sadd($ns, $key);
    $self->_redis->set($realkey, $data);

    if(defined($expires_at)) {
        my $secs = $expires_at - time;
        $self->_redis->expire($realkey, $secs);
    }
}

sub _verify_redis_connection {
    my ($self) = @_;

    try {
        $self->_redis->ping;
    } catch {
        my $params = $self->_params;
        $self->_redis(
            Redis->new(
                server => $params->{server} || '127.0.0.1:6379',
                debug => $params->{debug} || 0
            )
        );
    };
}

__PACKAGE__->meta->make_immutable;

no Moose;

__END__

=head1 NAME

CHI::Driver::Redis - The great new CHI::Driver::Redis!

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use CHI::Driver::Redis;

    my $foo = CHI::Driver::Redis->new();
    ...

=head1 AUTHOR

Cory G Watson, C<< <gphat at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-chi-driver-redis at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CHI-Driver-Redis>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2009 Cold Hard Code, LLC.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
