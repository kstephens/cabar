

Cabar::Plugin.new :name => 'cabar/test', :documentation => 'Unit Test discovery and execution support.' do

  facet :tests,
    :env_var => :CABAR_TESTS_PATH,
    :inferrable => false

  facet :test_capture_logs,
    :env_var => :CABAR_TEST_CAPTURE_LOGS_PATH,
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
      selection.to_a.each do | component |
        f = component.facet(:tests)
        if f
          puts "#{component.to_s.inspect}: #{f.abs_path.inspect}"
        end
      end
    end

    doc "
Run tests.
"
    cmd [ :run ] do
      # find component that defines a test_runner.
      # run test_runner command.
    end

  end # cmd_group

end # plugin


