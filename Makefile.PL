use inc::Module::Install;

name     'CHI-Driver-Redis';
all_from 'lib/CHI/Driver/Redis.pm';
author   q{Cory G Watson <gphat@cpan.org>};
license  'perl';

build_requires 'Test::Class';
build_requires 'Test::More';

requires 'Check::ISA';
requires 'CHI' => '0.36';
requires 'Moose';
requires 'Redis' => '1.2001';
requires 'Try::Tiny';
requires 'URI';

WriteAll;

