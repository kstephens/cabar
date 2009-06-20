# -*- ruby -*-
require 'cabar/test/main_helper'

describe 'cbr action' do
  include Cabar::Test::MainHelper

  it 'cbr act do --quiet dir' do
    example_main(:args => 'act do --quiet dir', 
                 :match_stdout => <<'EOF')
<<CABAR_BASE_DIR>>/example/repo/dev/c2/1.2
EOF
  end

  it 'cbr act do foo' do
    example_main(:args => 'act do foo', 
                 :match_stdout => <<'EOF')
component:
  c1/1.0:
    action: 
      "foo":
        expr: "echo foo \#{name} \#{version}"
        command: "echo foo c1 1.0"
        output: |
foo c1 1.0
                |
        result: true

component:
  c2/1.2:
    action: 
      "foo":
        expr: "echo foo"
        command: "echo foo"
        output: |
foo
EOF
  end
end
