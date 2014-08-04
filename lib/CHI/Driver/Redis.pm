package CHI::Driver::Redis;
use Moose;

use Check::ISA;
use Redis;
use Try::Tiny;
use URI::Escape qw(uri_escape uri_unescape);

extends 'CHI::Driver';

our $VERSION = '0.06';

has 'redis' => (
    is => 'rw',
    isa => 'Redis',
);

has '_params' => (
    is => 'rw'
);

sub BUILD {
    my ($self, $params) = @_;

    $self->_params($params);
}

sub _build_redis {
    my ($self) = @_;

    my $params = $self->_params;

    return Redis->new(
        server => $params->{server} || '127.0.0.1:6379',
        debug => $params->{debug} || 0,
        encoding => undef,
        (defined $params->{password} ? ( password => $params->{password} ) : ()),
    );
}

sub fetch {
    my ($self, $key) = @_;

    return unless $self->_verify_redis_connection;

    my $eskey = uri_escape($key);
    my $realkey = $self->namespace."||$eskey";
    my $val = $self->redis->get($realkey);
    return $val;
}

sub XXfetch_multi_hashref {
    my ($self, $keys) = @_;

    return unless scalar(@{ $keys });

    return unless $self->_verify_redis_connection;

    my %kv;
    foreach my $k (@{ $keys }) {
        my $esk = uri_escape($k);
        $kv{$self->namespace."||$esk"} = undef;
    }

    my @vals = $self->redis->mget(keys %kv);

    my $count = 0;
    my %resp;
    foreach my $k (@{ $keys }) {
        $resp{$k} = $vals[$count];
        $count++;
    }

    return \%resp;
}

sub get_keys {
    my ($self) = @_;

    return unless $self->_verify_redis_connection;

    my @keys = $self->redis->smembers($self->namespace);

    my @unesckeys = ();

    foreach my $k (@keys) {
        # Getting an empty key here for some reason...
        next unless defined $k;
        push(@unesckeys, uri_unescape($k));
    }
    return @unesckeys;
}

sub get_namespaces {
    my ($self) = @_;

    return unless $self->_verify_redis_connection;

    return $self->redis->smembers('chinamespaces');
}

sub remove {
    my ($self, $key) = @_;

    return unless defined($key);

    return unless $self->_verify_redis_connection;

    my $ns = $self->namespace;

    my $skey = uri_escape($key);

    $self->redis->srem($ns, $skey);
    $self->redis->del("$ns||$skey");
}

sub store {
    my ($self, $key, $data, $expires_in) = @_;

    return unless $self->_verify_redis_connection;

    my $ns = $self->namespace;

    my $skey = uri_escape($key);
    my $realkey = "$ns||$skey";

    $self->redis->sadd('chinamespaces', $ns);
    unless($self->redis->sismember($ns, $skey)) {
        $self->redis->sadd($ns, $skey) ;
    }
    $self->redis->set($realkey => $data);

    if (defined($expires_in)) {
        $self->redis->expire($realkey, $expires_in);
    }
}

sub _verify_redis_connection {
    my ($self) = @_;

    my $success = 0;
    try {
        if(defined($self->redis)) {
            if($self->redis->ping) {
                $success = 1;
                return;
            }
            # Bitch if the ping fails
            die "Ping failed.";
        }
    } catch {
        warn "Error pinging redis, attempting to reconnect.\n";
    };

    try {
        my $redis = $self->_build_redis();
        if(obj($redis, 'Redis')) {
            # We apparently connected, success!
            $self->redis($redis);
            $success = 1;
        } else {
            die('Failed to connect to Redis');
        }
    } catch {
        warn "Unable to connect to Redis: $_";
    };

    # Return the success of failure of the verification
    return $success;
}

__PACKAGE__->meta->make_immutable;

no Moose;

__END__

=head1 NAME

CHI::Driver::Redis - Redis driver for CHI

=head1 SYNOPSIS

    use CHI;

    my $foo = CHI->new(
        driver => 'Redis',
        namespace => 'foo',
        server => '127.0.0.1:6379',
        debug => 0
    );

=head1 DESCRIPTION

A CHI driver that uses C<Redis> to store the data.  Care has been taken to
not have this module fail in fiery ways if the cache is unavailable.  It is my
hope that if it is failing and the cache is not required for your work, you
can ignore it's warnings.

=head1 TECHNICAL DETAILS

=head2 Namespaces.

Redis does not have namespaces.  Therefore, we have to do some hoop-jumping.

Namespaces are tracked in a set named C<chinamespaces>.  This is a list of all
the namespaces the driver has seen.

Keys in a namespace are stored in a set that shares the name of the namespace.
The actual value is stored as "$namespace||key".

=head2 Encoding

This CHI driver uses Redis.pm.  Redis.pm by default automatically
encodes values to UTF-8.  This driver sets the Redis encoding option
to undef to disable automatic encoding.

=back

=head1 CONSTRUCTOR OPTIONS

C<server>, C<debug>, and C<password> are passed to C<Redis>.

=head1 ATTRIBUTES

=head2 redis

Contains the underlying C<Redis> object.

=head1 AUTHOR

Cory G Watson, C<< <gphat at cpan.org> >>

=head1 CONTRIBUTORS

Ian Burrell, C<< <iburrell@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Cold Hard Code, LLC.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
