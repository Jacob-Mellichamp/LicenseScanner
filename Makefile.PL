use 5.008004;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'LicenseScanner',
  VERSION_FROM     => 'lib/LicenseScanner.pm',
  ABSTRACT_FROM    => 'lib/LicenseScanner.pm',
  AUTHOR           => 'Jake Mellichamp',
  LICENSE          => 'perl_5',
  MIN_PERL_VERSION => '5.008004',
  EXE_FILES        => ['script/LicenseScanner.pl'],
  PREREQ_PM        => {
    'strict'   => 0,
    'warnings' => 0,
    'DateTime' => '0.37',
  },
  (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
      'meta-spec' => { version => 2 },
      resources => {
          repository => {
              type => 'git',
              url  => 'https://github.com/jmellichamp/LicenseScanner.git',
              web  => 'https://github.com/jmellichamp/LicenseScanner',
          },
      }})
   : ()
  ),
);