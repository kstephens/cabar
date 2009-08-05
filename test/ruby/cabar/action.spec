# -*- ruby -*-
require 'cabar/test/main_helper'

describe 'cbr action' do
  include Cabar::Test::MainHelper

  # NOTE: difficulties in correctly capturing stdout from Ruby leads to empty output: ||.
  it 'cbr act do --quiet dir' do
    example_main(:args => 'act do --quiet dir', 
                 :match_stdout => <<'EOF')
<<CABAR_BASE_DIR>>/example/repo/dev/c2/1.2
EOF
  end

  it 'cbr act do foo' do
    example_main(:args => 'act do foo', 
                 :match_stdout => <<'EOF')
foo c1 1.0
foo
component:
  c1/1.0:
    action: 
      "foo":
        expr: "echo foo \#{name} \#{version}"
        command: "echo foo c1 1.0"
        output: |
                |
        result: true

component:
  c2/1.2:
    action: 
      "foo":
        expr: "echo foo"
        command: "echo foo"
        output: |
                |
        result: true

EOF
  end

end # describe
