use Module::Build;

my $build = Module::Build->new(
    module_name        => 'Apache::FakeTable',
    license            => 'perl',
    create_makefile_pl => 'passthrough',
    configure_requires => { 'Module::Build' => '0.2701' },
    build_requires     => {
        'Module::Build' => '0.2701',
        'Test::More'    => '0.17',
    },
    recommends         => { 'Test::Pod'     => '1.20'   },
);
$build->create_build_script;
