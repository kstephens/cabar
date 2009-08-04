# -*- ruby -*-
require 'cabar/test/main_helper'

describe 'cbr comp' do
  include Cabar::Test::MainHelper

  it 'cbr comp list' do
    example_main(:args => 'comp list', 
                 # Ignore everything in cabar/contrib/
                 :filter_stdout => lambda { | x | x.gsub(%r{^.*/cabar/contrib/[^\n]+\n}, '') },
                 :match_stdout => 
<<"EOF"
---
cabar:
  version: "1.0"
  component: 
  - ["boc", "1.1", "<<CABAR_BASE_DIR>>/example/repo/dev/boc"]
  - ["boc", "1.0", "<<CABAR_BASE_DIR>>/example/repo/prod/boc"]
  - ["boc_config", "1.0", "<<CABAR_BASE_DIR>>/example/repo/prod/boc_config/1.0"]
  - ["boc_customer", "1.2", "<<CABAR_BASE_DIR>>/example/repo/prod/boc_customer/1.2"]
  - ["boc_locale", "2.0", "<<CABAR_BASE_DIR>>/example/repo/prod/boc_locale/2.0"]
  - ["boc_locale", "1.1", "<<CABAR_BASE_DIR>>/example/repo/prod/boc_locale/1.1"]
  - ["c1", "1.0", "<<CABAR_BASE_DIR>>/example/repo/dev/c1"]
  - ["c2", "1.2", "<<CABAR_BASE_DIR>>/example/repo/dev/c2/1.2"]
  - ["c2", "1.1", "<<CABAR_BASE_DIR>>/example/repo/dev/c2/1.1"]
  - ["c2", "1.0", "<<CABAR_BASE_DIR>>/example/repo/prod/c2/1.0"]
  - ["c3", "2.1", "<<CABAR_BASE_DIR>>/example/repo/prod/c3"]
  - ["cabar", "1.0", "<<CABAR_BASE_DIR>>"]
  - ["cabar_core", "1.0", "<<CABAR_BASE_DIR>>/comp/cabar_core"]
  - ["cabar_rubygems", "1.0", "<<CABAR_BASE_DIR>>/comp/cabar_rubygems"]
  - ["derby", "1.0", "<<CABAR_BASE_DIR>>/comp/derby/1.0"]
  - ["gems", "1.0", "<<CABAR_BASE_DIR>>/example/repo/plat/gems/1.0"]
  - ["perl", "<<ANY>>", "<<CABAR_BASE_DIR>>/comp/perl/std"]
  - ["rake", "0.1", "<<CABAR_BASE_DIR>>/comp/rake"]
  - ["ruby", "1.9", "<<CABAR_BASE_DIR>>/example/repo/plat/ruby/1.9"]
  - ["ruby", "<<ANY>>", "<<CABAR_BASE_DIR>>/comp/ruby/std"]
  - ["ruby", "1.8.4", "<<CABAR_BASE_DIR>>/example/repo/plat/ruby/1.8.4"]
  - ["rubygems", "<<ANY>>", "<<CABAR_BASE_DIR>>/comp/rubygems/std"]
  - ["todo", "1.1", "<<CABAR_BASE_DIR>>/example/repo/dev/todo"]
EOF
)
  end # it


  it 'cbr comp list - c2 --verbose' do
    example_main(:args => 'comp list - c2 --verbose', 
                 :match_stdout => 
<<"EOF"
---
cabar:
  version: "1.0"
  component: 
  - name:          "c2"
    version:       "1.2"
    enabled:       true
    directory:     "<<CABAR_BASE_DIR>>/example/repo/dev/c2/1.2"
    facet:         [ :"lib/ruby", :action, :bin, :env_var_C2_2_ENV, :env_var_C2_ENV ]
    requires:      [ "ruby/" ]
    plugins:       ["c2"]

  - name:          "c2"
    version:       "1.1"
    enabled:       true
    directory:     "<<CABAR_BASE_DIR>>/example/repo/dev/c2/1.1"
    facet:         [ :"lib/ruby", :bin ]
    requires:      [  ]

  - name:          "c2"
    version:       "1.0"
    enabled:       true
    directory:     "<<CABAR_BASE_DIR>>/example/repo/prod/c2/1.0"
    facet:         [ :"lib/ruby" ]
    requires:      [  ]

EOF
)
  end # it


end # describe

