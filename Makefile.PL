use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Net::Trackback',
    'VERSION_FROM'	=> 'lib/Net/Trackback.pm', # finds $VERSION
    'PREREQ_PM'		=> { LWP }, # e.g., Module::Name => 1.1
);
