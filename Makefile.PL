use inc::Module::Install;
use Module::Install::ReadmeFromPod;
use Module::Install::Repository;
name 'App-Benchmark-JobQueue';
all_from 'lib/App/Benchmark/JobQueue.pm';
readme_from 'lib/App/Benchmark/JobQueue.pm';

requires 'Test::mysqld';
requires 'Benchmark';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
build_requires 'Test::LoadAllModules';
build_requires 'Module::Install::ReadmeFromPod';
use_test_base;
auto_include;
auto_set_repository;
WriteAll;
