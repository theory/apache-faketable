use Module::Build;

my $build = Module::Build->new
  ( module_name        => 'Apache::FakeTable',
    license            => 'perl',
    create_makefile_pl => 'passthrough',
    build_requires     => { Test::Simple  => '0.17' },
    recommends         => {
        'Test::Pod'    => '1.20',
    },
  );
$build->create_build_script;
