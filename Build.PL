use Module::Build;

my $build = Module::Build->new
  ( module_name        => 'Apache::FakeTable',
    license            => 'perl',
    create_makefile_pl => 'passthrough',
  );
$build->create_build_script;
