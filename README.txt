= Introduction

See lib/ruby/cabar.rb for more info.

= Cabar Demo

* Go to cabar/example

    cd cabar/example

* Show bin/cbr_env.

    bin/cbr_env --env
    eval `bin/cbr_env --env`

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

    prod/boc_locale/1.1/cabar.yml
    prod/boc_config/1.0/cabar.rb

* Show graph:

    CABAR_PATH=@. cbr comp dot --show-dependencies
    cbr comp dot | dot -Tsvg:cairo -o graph.svg
    cbr comp dot --show-dependencies - c1 | dot -Tsvg:cairo -o graph.svg
    cbr comp dot --show-facets - c1 | dot -Tsvg:cairo -o graph.svg
    cbr comp dot --show-dependencies --show-facets - c1 | dot -Tsvg:cairo -o graph.svg

* Show in-place run scripts for ruby.

    cbr bin run - c1 c2_prog

* Show cabar as component

    (cd .. && CABAR_PATH=@. bin/cbr comp list)
    (cd .. && CABAR_PATH=@. bin/cbr run - cabar cbr list) 

* Show cbr-run on a #! line.

    cbr-run-test


= Known Issues:

* Component cannot define conflicting facets, commands or plugins, none of these are versionable.

* A faulty component's plugin may prevent entire system from working.


= TO DO:

* Add support for component.status; render component.status =
* :unimplemented, :in_progress, :complete

* Remove EnvVarPath, extend Path to support environment variables dynamically.

* Allow "- component/version" options to override cabar_config.yml require: definitions and CABAR_TOP_LEVEL env var;  Maybe add --override option?
 
* Allow facet prototypes to be defined in cabar.yml.

* Add documentation strings to Facet prototypes.

* Change Facet.key to Facet._key to avoid collision with future use.

* Change Facet.owner to Facet._owner

* Change Facet.context to Facet._context

* Add support to automatically require top_level components, via an attribute on a component in its cabar.yml file.


= From discussion with Jeremy 2008/03/10

* Unit test against example directory.

== Version control plugins

* CABAR_REMOTE_PATH specifies a remote list of repositories:
* CABAR_REMOTE_PATH="svn://rubyforge.org/package ; http://foobar.com/cabar ; p4://"
* CABAR_REMOTE_DEST specifies where "cabar remote get" will put components.

    cbr remote get -R cnuapp/1.1
    cbr remote list
    cbr remote update 

* Modify cabar config from command line.

    cbr config
    cbr config set select <component> 1.2

* Need web_service facet

    cbr bin lsws start
    cbr bin apache start

* Facets realizations are not scoped. Provide a mechanism to select particular component facets rather than entire components.

== Gem plugin

* Install gems into a gem platform component.

    cbr gems install rails - platform_gems/1.1

* Facets have top-level commands nameds after them:

    cbr action list
    cbr action run <action>
    cbr bin list
    cbr bin run <cmd> <args> ...
    cbr lib/ruby doc

* action run should be only on top-level components by default.

    cbr action -T run test
    cbr action run test

* runsv facet

    cbr runsv install <component> ...


