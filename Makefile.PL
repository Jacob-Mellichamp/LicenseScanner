use 5.008004;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'LicenseScanner',
  VERSION_FROM     => 'lib/LicenseScanner.pm',
  ABSTRACT_FROM    => 'lib/LicenseScanner.pm',
  AUTHOR           => 'Jake Mellichamp',
  LICENSE          => 'perl_5',
  MIN_PERL_VERSION => '5.008004',
  EXE_FILES        => ['scripts/LicenseScanner.pl'],
  PREREQ_PM        => {
	'Exporter' => 0,
	'Cwd' => 0,
	'File::Copy' => 0,
	'File::Find' => 0,
	'File::Path' => 0,
	'File::Spec' => 0,
	'File::Which' => 0,
	'JSON'     => '4.10',
    'strict'   => 0,
    'warnings' => 0,
  },
  (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
      'meta-spec' => { version => 2 },
      resources => {
          repository => {
              type => 'git',
              url  => 'https://github.com/Jacob-Mellichamp/LicenseScanner.git',
              web  => 'https://github.com/Jacob-Mellichamp/LicenseScanner',
          },
      }})
   : ()
  ),
);