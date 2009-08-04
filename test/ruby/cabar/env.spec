# -*- ruby -*-
require 'cabar/test/main_helper'

describe 'cbr env' do
  include Cabar::Test::MainHelper

  it 'cbr env # no args' do
    example_main(:args => 'env', 
                 :match_stdout => [ 
<<"EOF"
CABAR_TOP_LEVEL_COMPONENTS="boc"; export CABAR_TOP_LEVEL_COMPONENTS;
CABAR_REQUIRED_COMPONENTS="boc todo c1 boc_customer gems c3 c2 boc_locale boc_config rubygems cabar_rubygems cabar cabar_core ruby derby"; export CABAR_REQUIRED_COMPONENTS;
CABAR_PATH_SEP=":"; export CABAR_PATH_SEP;
CABAR_FACETS="bin,boc_config_path,boc_locale_path,components,env_var,env_var,include,lib,lib/perl,lib/ruby,rails/models,rakefile,rubygems,test_runner,tests"; export CABAR_FACETS;
CABAR_FACET_ENV_VAR_MAP="bin=PATH,boc_config_path=BOC_CONFIG_PATH,boc_locale_path=BOC_LOCALE_PATH,env_var=C2_2_ENV,env_var=C2_ENV,include=INCLUDE_PATH,lib/perl=PERL5LIB,lib/ruby=RUBYLIB,lib=LD_LIBRARY_PATH,rai
ls/models=RAILS_MODELS_PATH,rakefile=CABAR_RAKE_FILE,rubygems=GEM_PATH,test_runner=CABAR_TEST_RUNNER,tests=CABAR_TESTS_PATH"; export CABAR_FACET_ENV_VAR_MAP;
CABAR_boc_NAME="boc"; export CABAR_boc_NAME;
CABAR_boc_VERSION="1.1"; export CABAR_boc_VERSION;
CABAR_boc_DIRECTORY="<<CABAR_BASE_DIR>>/example/repo/dev/boc"; export CABAR_boc_DIRECTORY;
CABAR_boc_BASE_DIRECTORY="<<CABAR_BASE_DIR>>/example/repo/dev/boc"; export CABAR_boc_BASE_DIRECTORY;
CABAR_boc_PATH="<<CABAR_BASE_DIR>>/example/repo/dev/boc/bin"; export CABAR_boc_PATH;
CABAR_boc_CABAR_RAKE_FILE="<<CABAR_BASE_DIR>>/example/repo/dev/boc/Rakefile!boc"; export CABAR_boc_CABAR_RAKE_FILE;
CABAR_todo_NAME="todo"; export CABAR_todo_NAME;
CABAR_todo_VERSION="1.1"; export CABAR_todo_VERSION;
CABAR_todo_DIRECTORY="<<CABAR_BASE_DIR>>/example/repo/dev/todo"; export CABAR_todo_DIRECTORY;
CABAR_todo_BASE_DIRECTORY="<<CABAR_BASE_DIR>>/example/repo/dev/todo"; export CABAR_todo_BASE_DIRECTORY;
CABAR_todo_PATH="<<CABAR_BASE_DIR>>/example/repo/dev/todo/bin"; export CABAR_todo_PATH;
CABAR_c1_NAME="c1"; export CABAR_c1_NAME;
CABAR_c1_VERSION="1.0"; export CABAR_c1_VERSION;
CABAR_c1_DIRECTORY="<<CABAR_BASE_DIR>>/example/repo/dev/c1"; export CABAR_c1_DIRECTORY;
CABAR_c1_BASE_DIRECTORY="<<CABAR_BASE_DIR>>/example/repo/dev/c1"; export CABAR_c1_BASE_DIRECTORY;
CABAR_c1_RUBYLIB="<<CABAR_BASE_DIR>>/example/repo/dev/c1/lib/ruby"; export CABAR_c1_RUBYLIB;
CABAR_c1_PATH="<<CABAR_BASE_DIR>>/example/repo/dev/c1/bin"; export CABAR_c1_PATH;
CABAR_c1_CABAR_RAKE_FILE="<<CABAR_BASE_DIR>>/example/repo/dev/c1/Rakefile!c1"; export CABAR_c1_CABAR_RAKE_FILE;
CABAR_boc_customer_NAME="boc_customer"; export CABAR_boc_customer_NAME;
CABAR_boc_customer_VERSION="1.2"; export CABAR_boc_customer_VERSION;
CABAR_boc_customer_DIRECTORY="<<CABAR_BASE_DIR>>/example/repo/prod/boc_customer/1.2"; export CABAR_boc_customer_DIRECTORY;
CABAR_boc_customer_BASE_DIRECTORY="<<CABAR_BASE_DIR>>/example/repo/prod/boc_customer/1.2"; export CABAR_boc_customer_BASE_DIRECTORY;
CABAR_boc_customer_BOC_LOCALE_PATH="<<CABAR_BASE_DIR>>/example/repo/prod/boc_customer/1.2/locale"; export CABAR_boc_customer_BOC_LOCALE_PATH;
CABAR_boc_customer_BOC_CONFIG_PATH="<<CABAR_BASE_DIR>>/example/repo/prod/boc_customer/1.2/conf"; export CABAR_boc_customer_BOC_CONFIG_PATH;
CABAR_boc_customer_RUBYLIB="<<CABAR_BASE_DIR>>/example/repo/prod/boc_customer/1.2/lib"; export CABAR_boc_customer_RUBYLIB;
CABAR_gems_NAME="gems"; export CABAR_gems_NAME;
CABAR_gems_VERSION="1.0"; export CABAR_gems_VERSION;
CABAR_gems_DIRECTORY="<<CABAR_BASE_DIR>>/example/repo/plat/gems/1.0"; export CABAR_gems_DIRECTORY;
CABAR_gems_BASE_DIRECTORY="<<CABAR_BASE_DIR>>/example/repo/plat/gems/1.0"; export CABAR_gems_BASE_DIRECTORY;
CABAR_gems_GEM_PATH="<<CABAR_BASE_DIR>>/example/repo/plat/gems/1.0/gems-<<ANY>>"; export CABAR_gems_GEM_PATH;
CABAR_c3_NAME="c3"; export CABAR_c3_NAME;
CABAR_c3_VERSION="2.1"; export CABAR_c3_VERSION;
CABAR_c3_DIRECTORY="<<CABAR_BASE_DIR>>/example/repo/prod/c3"; export CABAR_c3_DIRECTORY;
CABAR_c3_BASE_DIRECTORY="<<CABAR_BASE_DIR>>/example/repo/prod/c3"; export CABAR_c3_BASE_DIRECTORY;
CABAR_c3_BOC_CONFIG_PATH="<<CABAR_BASE_DIR>>/example/repo/prod/c3/etc"; export CABAR_c3_BOC_CONFIG_PATH;
CABAR_c3_LD_LIBRARY_PATH="<<CABAR_BASE_DIR>>/example/repo/prod/c3/lib"; export CABAR_c3_LD_LIBRARY_PATH;
CABAR_c3_INCLUDE_PATH="<<CABAR_BASE_DIR>>/example/repo/prod/c3/include"; export CABAR_c3_INCLUDE_PATH;
CABAR_c3_PATH="<<CABAR_BASE_DIR>>/example/repo/prod/c3/bin"; export CABAR_c3_PATH;
CABAR_c2_NAME="c2"; export CABAR_c2_NAME;
CABAR_c2_VERSION="1.2"; export CABAR_c2_VERSION;
CABAR_c2_DIRECTORY="<<CABAR_BASE_DIR>>/example/repo/dev/c2/1.2"; export CABAR_c2_DIRECTORY;
CABAR_c2_BASE_DIRECTORY="<<CABAR_BASE_DIR>>/example/repo/dev/c2/1.2"; export CABAR_c2_BASE_DIRECTORY;
CABAR_c2_C2_ENV="1.2 in dev"; export CABAR_c2_C2_ENV;
CABAR_c2_RUBYLIB="<<CABAR_BASE_DIR>>/example/repo/dev/c2/1.2/lib/ruby"; export CABAR_c2_RUBYLIB;
CABAR_c2_PATH="<<CABAR_BASE_DIR>>/example/repo/dev/c2/1.2/bin"; export CABAR_c2_PATH;
CABAR_c2_CONFIG_foo="bar"; export CABAR_c2_CONFIG_foo;
CABAR_boc_locale_NAME="boc_locale"; export CABAR_boc_locale_NAME;
CABAR_boc_locale_VERSION="1.1"; export CABAR_boc_locale_VERSION;
CABAR_boc_locale_DIRECTORY="<<CABAR_BASE_DIR>>/example/repo/prod/boc_locale/1.1"; export CABAR_boc_locale_DIRECTORY;
CABAR_boc_locale_BASE_DIRECTORY="<<CABAR_BASE_DIR>>/example/repo/prod/boc_locale/1.1"; export CABAR_boc_locale_BASE_DIRECTORY;
CABAR_boc_locale_BOC_CONFIG_PATH="<<CABAR_BASE_DIR>>/example/repo/prod/boc_locale/1.1/etc"; export CABAR_boc_locale_BOC_CONFIG_PATH;
CABAR_boc_locale_RUBYLIB="<<CABAR_BASE_DIR>>/example/repo/prod/boc_locale/1.1/lib"; export CABAR_boc_locale_RUBYLIB;
CABAR_boc_config_NAME="boc_config"; export CABAR_boc_config_NAME;
CABAR_boc_config_VERSION="1.0"; export CABAR_boc_config_VERSION;
CABAR_boc_config_DIRECTORY="<<CABAR_BASE_DIR>>/example/repo/prod/boc_config/1.0"; export CABAR_boc_config_DIRECTORY;
CABAR_boc_config_BASE_DIRECTORY="<<CABAR_BASE_DIR>>/example/repo/prod/boc_config/1.0"; export CABAR_boc_config_BASE_DIRECTORY;
CABAR_boc_config_RUBYLIB="<<CABAR_BASE_DIR>>/example/repo/prod/boc_config/1.0/lib"; export CABAR_boc_config_RUBYLIB;
CABAR_boc_config_CABAR_RAKE_FILE="<<CABAR_BASE_DIR>>/example/repo/prod/boc_config/1.0/Rakefile!boc_config"; export CABAR_boc_config_CABAR_RAKE_FILE;
CABAR_rubygems_NAME="rubygems"; export CABAR_rubygems_NAME;
CABAR_rubygems_VERSION="<<ANY>>"; export CABAR_rubygems_VERSION;
CABAR_rubygems_DIRECTORY="<<CABAR_BASE_DIR>>/comp/rubygems/std"; export CABAR_rubygems_DIRECTORY;
CABAR_rubygems_BASE_DIRECTORY="<<CABAR_BASE_DIR>>/comp/rubygems/std"; export CABAR_rubygems_BASE_DIRECTORY;
CABAR_cabar_NAME="cabar"; export CABAR_cabar_NAME;
CABAR_cabar_VERSION="1.0"; export CABAR_cabar_VERSION;
CABAR_cabar_DIRECTORY="<<CABAR_BASE_DIR>>"; export CABAR_cabar_DIRECTORY;
CABAR_cabar_BASE_DIRECTORY="<<CABAR_BASE_DIR>>"; export CABAR_cabar_BASE_DIRECTORY;
CABAR_cabar_RUBYLIB="<<CABAR_BASE_DIR>>/lib/ruby"; export CABAR_cabar_RUBYLIB;
CABAR_cabar_PATH="<<CABAR_BASE_DIR>>/bin"; export CABAR_cabar_PATH;
CABAR_cabar_CABAR_RAKE_FILE="<<CABAR_BASE_DIR>>/Rakefile!cabar"; export CABAR_cabar_CABAR_RAKE_FILE;
CABAR_ruby_NAME="ruby"; export CABAR_ruby_NAME;
CABAR_ruby_VERSION="<<ANY>>"; export CABAR_ruby_VERSION;
CABAR_ruby_DIRECTORY="<<CABAR_BASE_DIR>>/comp/ruby/std"; export CABAR_ruby_DIRECTORY;
CABAR_ruby_BASE_DIRECTORY="<<ANY>>"; export CABAR_ruby_BASE_DIRECTORY;
CABAR_ruby_RUBYLIB="<<ANY>><<CABAR_BASE_DIR>>/lib/ruby:<<ANY>>:."; export CABAR_ruby_RUBYLIB;
CABAR_ruby_PATH="<<ANY>>"; export CABAR_ruby_PATH;
CABAR_ENV_PERL5LIB="<<ANY>>"; export CABAR_ENV_PERL5LIB;
PERL5LIB="<<ANY>>"; export PERL5LIB;
CABAR_ENV_C2_ENV="1.2 in dev"; export CABAR_ENV_C2_ENV;
C2_ENV="1.2 in dev"; export C2_ENV;
CABAR_ENV_LD_LIBRARY_PATH="<<CABAR_BASE_DIR>>/example/repo/prod/c3/lib"; export CABAR_ENV_LD_LIBRARY_PATH;
LD_LIBRARY_PATH="<<CABAR_BASE_DIR>>/example/repo/prod/c3/lib"; export LD_LIBRARY_PATH;
CABAR_ENV_BOC_CONFIG_PATH="<<CABAR_BASE_DIR>>/example/repo/prod/boc_customer/1.2/conf:<<CABAR_BASE_DIR>>/example/repo/prod/c3/etc:<<CABAR_BASE_DIR>>/example/repo/prod/boc_locale/1.1/etc"; export CABAR_ENV_BOC_CONFIG_PATH;
BOC_CONFIG_PATH="<<CABAR_BASE_DIR>>/example/repo/prod/boc_customer/1.2/conf:<<CABAR_BASE_DIR>>/example/repo/prod/c3/etc:<<CABAR_BASE_DIR>>/example/repo/prod/boc_locale/1.1/etc"; export BOC_CONFIG_PATH;
CABAR_ENV_BOC_LOCALE_PATH="<<CABAR_BASE_DIR>>/example/repo/prod/boc_customer/1.2/locale"; export CABAR_ENV_BOC_LOCALE_PATH;
BOC_LOCALE_PATH="<<CABAR_BASE_DIR>>/example/repo/prod/boc_customer/1.2/locale"; export BOC_LOCALE_PATH;
CABAR_ENV_INCLUDE_PATH="<<CABAR_BASE_DIR>>/example/repo/prod/c3/include"; export CABAR_ENV_INCLUDE_PATH;
INCLUDE_PATH="<<CABAR_BASE_DIR>>/example/repo/prod/c3/include"; export INCLUDE_PATH;
CABAR_ENV_RUBYLIB="<<ANY>>:."; export CABAR_ENV_RUBYLIB;
RUBYLIB="<<ANY>><<CABAR_BASE_DIR>>/example/repo/dev/c1/lib/ruby:<<CABAR_BASE_DIR>>/example/repo/prod/boc_customer/1.2/lib:<<CABAR_BASE_DIR>>/example/repo/dev/c2/1.2/lib/ruby:<<CABAR_BASE_DIR>>/example/repo/prod/boc_locale/1.1/lib:<<CABAR_BASE_DIR>>/example/repo/prod/boc_config/1.0/lib:<<CABAR_BASE_DIR>>/comp/derby/1.0/lib/ruby:<<CABAR_BASE_DIR>>/comp/cabar_core/lib/ruby:<<CABAR_BASE_DIR>>/example:<<CABAR_BASE_DIR>>/lib/ruby:<<ANY>>:."; export RUBYLIB;
CABAR_ENV_CABAR_RAKE_FILE="<<CABAR_BASE_DIR>>/example/repo/dev/boc/Rakefile!boc:<<CABAR_BASE_DIR>>/example/repo/dev/c1/Rakefile!c1:<<CABAR_BASE_DIR>>/example/repo/prod/boc_config/1.0/Rakefile!boc_config:<<CABAR_BASE_DIR>>/Rakefile!cabar:<<CABAR_BASE_DIR>>/comp/derby/1.0/Rakefile!derby:<<CABAR_BASE_DIR>>/comp/cabar_core/Rakefile!cabar_core:<<CABAR_BASE_DIR>>/example/repo/dev/boc/Rakefile!boc!:<<CABAR_BASE_DIR>>/example/repo/dev/c1/Rakefile!c1!:<<CABAR_BASE_DIR>>/example/repo/prod/boc_config/1.0/Rakefile!boc_config!:<<CABAR_BASE_DIR>>/Rakefile!cabar!:<<CABAR_BASE_DIR>>/comp/derby/1.0/Rakefile!derby!:<<CABAR_BASE_DIR>>/comp/cabar_core/Rakefile!cabar_core!:<<CABAR_BASE_DIR>>/example/repo/dev/boc/Rakefile!boc!!:<<CABAR_BASE_DIR>>/example/repo/dev/c1/Rakefile!c1!!:<<CABAR_BASE_DIR>>/example/repo/prod/boc_config/1.0/Rakefile!boc_config!!:<<CABAR_BASE_DIR>>/Rakefile!cabar!!:<<CABAR_BASE_DIR>>/comp/derby/1.0/Rakefile!derby!!:<<CABAR_BASE_DIR>>/comp/cabar_core/Rakefile!cabar_core!!"; export CABAR_ENV_CABAR_RAKE_FILE;
CABAR_RAKE_FILE="<<CABAR_BASE_DIR>>/example/repo/dev/boc/Rakefile!boc:<<CABAR_BASE_DIR>>/example/repo/dev/c1/Rakefile!c1:<<CABAR_BASE_DIR>>/example/repo/prod/boc_config/1.0/Rakefile!boc_config:<<CABAR_BASE_DIR>>/Rakefile!cabar:<<CABAR_BASE_DIR>>/comp/derby/1.0/Rakefile!derby:<<CABAR_BASE_DIR>>/comp/cabar_core/Rakefile!cabar_core:<<CABAR_BASE_DIR>>/example/repo/dev/boc/Rakefile!boc!:<<CABAR_BASE_DIR>>/example/repo/dev/c1/Rakefile!c1!:<<CABAR_BASE_DIR>>/example/repo/prod/boc_config/1.0/Rakefile!boc_config!:<<CABAR_BASE_DIR>>/Rakefile!cabar!:<<CABAR_BASE_DIR>>/comp/derby/1.0/Rakefile!derby!:<<CABAR_BASE_DIR>>/comp/cabar_core/Rakefile!cabar_core!:<<CABAR_BASE_DIR>>/example/repo/dev/boc/Rakefile!boc!!:<<CABAR_BASE_DIR>>/example/repo/dev/c1/Rakefile!c1!!:<<CABAR_BASE_DIR>>/example/repo/prod/boc_config/1.0/Rakefile!boc_config!!:<<CABAR_BASE_DIR>>/Rakefile!cabar!!:<<CABAR_BASE_DIR>>/comp/derby/1.0/Rakefile!derby!!:<<CABAR_BASE_DIR>>/comp/cabar_core/Rakefile!cabar_core!!"; export CABAR_RAKE_FILE;
CABAR_ENV_PATH="<<CABAR_BASE_DIR>>/example/repo/dev/boc/bin:<<CABAR_BASE_DIR>>/example/repo/dev/c1/bin:<<CABAR_BASE_DIR>>/example/repo/prod/c3/bin:<<CABAR_BASE_DIR>>/example/repo/dev/c2/1.2/bin:<<CABAR_BASE_DIR>>/bin:<<ANY>>"; export CABAR_ENV_PATH;
PATH="<<CABAR_BASE_DIR>>/example/repo/dev/boc/bin:<<CABAR_BASE_DIR>>/example/repo/dev/c1/bin:<<CABAR_BASE_DIR>>/example/repo/prod/c3/bin:<<CABAR_BASE_DIR>>/example/repo/dev/c2/1.2/bin:<<CABAR_BASE_DIR>>/bin:<<ANY>>"; export PATH;
CABAR_ENV_GEM_PATH="<<CABAR_BASE_DIR>>/example/repo/plat/gems/1.0/gems-<<ANY>>"; export CABAR_ENV_GEM_PATH;
GEM_PATH="<<CABAR_BASE_DIR>>/example/repo/plat/gems/1.0/gems-<<ANY>>"; export GEM_PATH;
CABAR_ENV_TEST1="test1"; export CABAR_ENV_TEST1;
TEST1="test1"; export TEST1;
CABAR_ENV_TEST2="test2"; export CABAR_ENV_TEST2;
TEST2="test2"; export TEST2;
unset CABAR_ENV_TEST3;
unset TEST3;
EOF
]
)
  end


  it 'cbr env - boc -T --selected' do
    example_main(:args => 'env - boc -T --selected',
                 :match_stdout => <<'EOF')
CABAR_ENV_SELECTED_COMPONENTS="boc"; export CABAR_ENV_SELECTED_COMPONENTS;
SELECTED_COMPONENTS="boc"; export SELECTED_COMPONENTS;
CABAR_PATH_SEP=":"; export CABAR_PATH_SEP;
CABAR_FACETS="bin,boc_config_path,boc_locale_path,components,env_var,include,lib,lib/perl,lib/ruby,rails/models,rakefile,rubygems,test_runner,tests"; export CABAR_FACETS;
CABAR_FACET_ENV_VAR_MAP="bin=PATH,boc_config_path=BOC_CONFIG_PATH,boc_locale_path=BOC_LOCALE_PATH,env_var=C2_ENV,include=INCLUDE_PATH,lib/perl=PERL5LIB,lib/ruby=RUBYLIB,lib=LD_LIBRARY_PATH,rails/models=RAILS_MODELS_PATH,rakefile=CABAR_RAKE_FILE,rubygems=GEM_PATH,test_runner=CABAR_TEST_RUNNER,tests=CABAR_TESTS_PATH"; export CABAR_FACET_ENV_VAR_MAP;
CABAR_boc_NAME="boc"; export CABAR_boc_NAME;
CABAR_boc_VERSION="1.1"; export CABAR_boc_VERSION;
CABAR_boc_DIRECTORY="<<CABAR_BASE_DIR>>/example/repo/dev/boc"; export CABAR_boc_DIRECTORY;
CABAR_boc_BASE_DIRECTORY="<<CABAR_BASE_DIR>>/example/repo/dev/boc"; export CABAR_boc_BASE_DIRECTORY;
CABAR_boc_PATH="<<CABAR_BASE_DIR>>/example/repo/dev/boc/bin"; export CABAR_boc_PATH;
CABAR_boc_CABAR_RAKE_FILE="<<CABAR_BASE_DIR>>/example/repo/dev/boc/Rakefile!boc"; export CABAR_boc_CABAR_RAKE_FILE;
CABAR_boc_TEST1="test1"; export CABAR_boc_TEST1;
CABAR_boc_TEST2="test2"; export CABAR_boc_TEST2;
unset CABAR_boc_TEST3;
EOF
    end
end
