use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'		=> 'Net::TrackBack',
    'VERSION_FROM'	=> 'TrackBack.pm',
    'PREREQ_PM'		=> {LWP},
    ($] >= 5.005 ?
      (ABSTRACT_FROM => 'TrackBack.pm', 
       AUTHOR     => 'Timothy Appnel <tima@mplode.com>') : ()),
);
