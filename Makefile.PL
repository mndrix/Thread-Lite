use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Thread::Lite',
    AUTHOR              => 'Michael Hendricks <michael@ndrix.org>',
    VERSION_FROM        => 'lib/Thread/Lite.pm',
    ABSTRACT_FROM       => 'lib/Thread/Lite.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'mit')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'AnyEvent'   => 0,
        'Sys::CPU'   => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Thread-Lite-*' },
);
