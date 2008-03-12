= Introduction

See lib/ruby/cabar.rb for more info.

= Cabar Demo

* Go to cabar/example

  cd cabar/example

* Show bin/env.

  bin/env --env
  eval `bin/env --env`

* List available commands.

  cbr help
  cbr --verbose help comp

* List plugins.

  cbr plugin list

* List available components.

  cbr comp list
  cbr comp list - c2

* Show directory structure.

* Cabar cabar.yml specification.

* Show components and facets:

  cbr comp show - c1

* Show component version selection:

  cbr comp run - c2 c2_prog foo bar

  cbr comp run - c2/1.1 c2_prog foo bar

* Cabar configuration cabar_conf.yml.

Show how component version selection can be done outside
of component requirements.

1. Version Selection
2. Dependencies
3. Version Defaults

  cbr comp show - c1

* Show facet environment for a component.:

  cbr env - c1

* Show plugins:

prod/cnu_config/1.0/cabar.rb

prod/cnu_locale/1.1/cabar.yml : provides.cnu_config_path

* Show graph:

  CABAR_PATH=@. cbr comp dot --show-dependencies

  cbr comp dot | dot -Tsvg:cairo -o graph.svg

  cbr comp dot --show-dependencies - c1 | dot -Tsvg:cairo -o graph.svg

  cbr comp dot --show-facets - c1 | dot -Tsvg:cairo -o graph.svg

  cbr comp dot --show-dependencies --show-facets - c1 | dot -Tsvg:cairo -o graph.svg

* Show in-place run scripts for ruby.

  cbr bin run - c1 c2_prog

* Show cabar as component

(cd .. && CABAR_PATH=.. bin/cbr comp list)
(cd .. && CABAR_PATH=.. bin/cbr run - cabar cbr list) 

* Show cbr-run on a #! line.

  cbr-run-test


= TO DO:

* Change Facet.key to Facet._key to avoid collision with future use.

* Change Facet.owner to Facet._owner

* Change Facet.context to Facet._context

* Add support to automatically require top_level components.

* From discussion with Jeremy 2008/03/10
** example directory needs README/docs.
** Unit test against example directory.

** Create Cabar::Plugin::Builder DSL
*** Create facets
*** Create commands for facets

** Version control plugins
*** CABAR_REMOTE_PATH specifies a remote list of repositories:
**** CABAR_REMOTE_PATH="svn://rubyforge.org/package ; http://foobar.com/cabar ; p4://"
*** CABAR_REMOTE_DEST specifies where "cabar remote get" will put components.
cbr remote get -R cnuapp/1.1
cbr remote list
cbr remote update 

* Modify cabar config
** cbr config
** cbr config set select <component> 1.2

* Need web_service facet
** cbr bin lsws start
** cbr bin apache start

* Facets realizations are not scoped.
** Provide a mechanism to select particular component facets rather than
entire components

* Gem plugin

** Install gems into a gem platform component.

*** cbr gems install rails - cnu_gems/1.1

* All facets have top-level commands
** cbr action list
** cbr action run <action>
** cbr bin list
** cbr bin run <cmd> <args> ...
** cbr lib/ruby doc

* action run should be only on top-level components by default.
** cbr action run test
** cbr action -R run test

* runsv facet
** cbr runsv install <component> ...

