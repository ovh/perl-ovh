use ExtUtils::MakeMaker;
use utf8;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME           => 'OvhApi',
    VERSION        => '1.2',
    PREREQ_PM      => {
        'LWP::UserAgent' => '6.44',
        'JSON'           => '2.97',
    },
    ABSTRACT       => "Perl wrapper around OVH's APIs",
    AUTHOR         => 'Romain Beuque <romain.beuque@ovhcloud.com>',
);
