use inc::Module::Install;

name     'CHI-Driver-Redis';
all_from 'lib/CHI/Driver/Redis.pm';
author   q{Cory G Watson <gphat@cpan.org>};
license  'perl';

build_requires 'Test::Class';
build_requires 'Test::More';

requires 'CHI';
requires 'Moose';
requires 'Redis';
requires 'Try::Tiny';
requires 'URI';

WriteAll;

