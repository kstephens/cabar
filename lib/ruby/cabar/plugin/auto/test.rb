

Cabar::Plugin.new :name => 'cabar/test', :documentation => 'Unit Test discovery and execution support.' do

  facet :tests,
    :env_var => :CABAR_TESTS_PATH,
    :inferrable => false

  facet :test_runner,
    # :class => Cabar::Facet::Executable,
    :env_var => :CABAR_TEST_RUNNER,
    :inferrable => false

  cmd_group [ :test ] do
    doc "
List all test directories.
"
    cmd [ :list, :ls ] do
      puts 
    end

    doc "
Run tests.
"
    cmd [ :run ] do
      puts
    end

  end # cmd_group

end # plugin


