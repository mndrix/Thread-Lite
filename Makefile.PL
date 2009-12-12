use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Sub::Future',
    AUTHOR              => 'Michael Hendricks <michael@ndrix.org>',
    VERSION_FROM        => 'lib/Sub/Future.pm',
    ABSTRACT_FROM       => 'lib/Sub/Future.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'mit')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Sub-Future-*' },
);
