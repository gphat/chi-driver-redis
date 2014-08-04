use inc::Module::Install;

name     'CHI-Driver-Redis';
version_from 'lib/CHI/Driver/Redis.pm';
author   q{Cory G Watson <gphat@cpan.org>};
license  'perl';
repository 'https://github.com/rentrak/chi-driver-redis';

perl_version '5.006';

build_requires 'Test::Class';
build_requires 'Test::More';

requires 'Check::ISA';
requires 'CHI' => '0.36';
requires 'Moose';
requires 'Redis' => '1.901';
requires 'Try::Tiny';
requires 'URI';

WriteAll;

