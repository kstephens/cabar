INTRODUCTION:

See lib/ruby/cabar.rb for more info.

TO DO:

* Change Facet.key to Facet._key to avoid collision with future use.

* Change Facet.owner to Facet._owner

* Change Facet.context to Facet._context

* Change 'actions' facet to 'action' to be in alignment with
facet commands.

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

* actions should be only on top-level components by default.
** cbr action run test
** cbr action -R run test

* runsv facet
** cbr runsv install <component> ...

Cabar Demo

* Show bin/env.

* List available commands

bin/env cbr help
bin/env cbr --verbose help comp

* List available components.

bin/env cbr comp list
bin/env cbr comp list - c2

* Show directory structure.

* Cabar cabar.yml specification.

* Show components and facets:

bin/env cbr show - c1

* Show component version selection:

bin/env cbr run - c2 c2_prog foo bar

bin/env cbr run - c2/1.1 c2_prog foo bar

* Cabar configuration cabar_conf.yml.

Show how component version selection can be done outside
of component requirements.

1. Version Selection
2. Dependencies
3. Version Defaults

bin/env cbr comp show - c1

* Show environment:

bin/env cbr env c1


* Show plugins:

prod/cnu_config/1.0/cabar.rb

prod/cnu_locale/1.1/cabar.yml : provides.cnu_config_path

* Show graph:

bin/env cbr comp dot | dot -Tsvg:cairo -o graph.svg

bin/env cbr comp dot --show-dependencies - c1 | dot -Tsvg:cairo -o graph.svg

bin/env cbr comp dot --show-facets - c1 | dot -Tsvg:cairo -o graph.svg

bin/env cbr comp dot --show-dependencies --show-facets - c1 | dot -Tsvg:cairo -o graph.svg

* Show in-place run scripts for ruby.

bin/env cbr run - c1 c2_prog

* Show cabar as component

(cd .. && CABAR_PATH=.. bin/cbr comp list)
(cd .. && CABAR_PATH=.. bin/cbr run - cabar cbr list) 

* Show cbr-run on a #! line.

bin/env cbr-run-test
