use inc::Module::Install 0.93;
use strict;
use warnings;
use POSIX ();

use 5.008001;

name     'DBIx-Class-DigestColumns';
perl_version '5.008001';
all_from 'lib/DBIx/Class/DigestColumns.pm';
readme_from 'lib/DBIx/Class/DigestColumns.pm';

build_requires 'DBD::SQLite' => 1.25;


requires 'DBIx::Class' => 0.08121;
requires 'Digest::MD5' => 0;
requires 'Digest'      => 1.11;
requires 'Digest::SHA' => 0;

configure_requires 'DBIx::Class' => '0.08121';

require DBIx::Class::Optional::Dependencies;
my $deploy_deps = DBIx::Class::Optional::Dependencies->req_list_for ('deploy');
test_requires $_ => $deploy_deps->{$_}
   for keys %$deploy_deps;

auto_install();

tests_recursive('t');

resources 'IRC'         => 'irc://irc.perl.org/#dbix-class';
resources 'license'     => 'http://dev.perl.org/licenses/';
resources 'repository'  => 'http://dev.catalyst.perl.org/repos/bast/trunk/DBIx-Class-DigestColumns/';

WriteAll();
