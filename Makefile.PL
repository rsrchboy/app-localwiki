
sub githubmeta  { warn 'You need Module::Install::GithubMeta installed' }
sub extra_tests { warn 'You need Module::Install::ExtraTests installed' }

use inc::Module::Install;

my $main_module = '';

githubmeta;

name     '';
all_from $main_module;
author   q{Chris Weyl <cweyl@alumni.drew.edu>};
license  'lgpl';

readme_from $main_module;
readme_markdown_from $main_module;

requires 'namespace::autoclean' => '0.09';
requires 'Moose' => '0.94';

test_requires 'Test::More';
test_requires 'Test::Moose';
test_requires 'Test::UseAllModules';

author_requires 'File::Find::Rule';
author_requires 'FindBin';
author_requires 'Module::ScanDeps';

extra_tests;
auto_install;
auto_provides;
write_mymeta_json;

WriteAll;

