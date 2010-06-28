use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name			    => 'Voter::NVRA',
    license			    => 'lgpl',
    dist_author			    => q{Naveen Manivannan <naveen.manivannan@gmail.com>},
    build_requires		    => {
        'Test::More'		    => 0,
        'Test::Exception'	    => 0.27,
    },
    add_to_cleanup		    => [ 'Voter-*' ],
#    create_makefile_pl		    => 'traditional',
#    pod_files			    => {'NVRA.pm' => 'lib/Voter/NVRA.pm'},
    share_dir			    => 'share',			 
    create_readme		    => 1,
	create_license => 1,			 
  auto_features => {
    dist_authoring => {
      description => "Create new distributions",
      requires => {
		   'XML::Simple' => 2.18,	   
		   'Text::MicroTemplate'	    => 0.11,
		   'Text::MicroTemplate::File' => 0,
		   'Carp' => 0,
		   'Time::Local' => 1.18,
		   'File::Temp' => 0.22,
      },
      recommends => {
      },
    },
    license_creation => {
      description => "Create licenses automatically in distributions",
      requires => {
        'Software::License'  => 0,
      },
    },
}
);

$builder->create_build_script();
