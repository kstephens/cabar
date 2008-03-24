= Introduction

See lib/ruby/cabar.rb or http://cabar.rubyforge.org/ for more info.

= Quick Cabar Demo

* Go to cabar/example

    > cd cabar/example

* See bin/cbr_env.

    > bin/cbr_env --env
    > eval `bin/cbr_env --env`

* List available commands.

    > cbr help
    > cbr --verbose help comp

* List plugins.

    > cbr plugin list

* List available components.

    > cbr comp list
    > cbr comp list - c2

* Show directory structure.

    > find . -type d

* Cabar cabar.yml specification.

    > find . -type f -name 'cabar.yml'

* Show components and facets:

    > cbr comp show - c1

* Show component version selection:

    > cbr comp run - c2 c2_prog foo bar
    > cbr comp run - c2/1.1 c2_prog foo bar

* Cabar configuration cabar_conf.yml.

Show how component version selection can be done outside
of component requirements.

1. Version Selection
2. Dependencies
3. Version Defaults

    > cbr comp show - c1

* Show facet environment for a component:

    > cbr env - c1

* See plugins:

    > cat prod/boc_locale/1.1/cabar.yml
    > cat prod/boc_config/1.0/cabar.rb

* Show graph:

    > CABAR_PATH=@. cbr comp dot --show-dependencies
    > cbr comp dot | dot -Tsvg:cairo -o graph.svg
    > cbr comp dot --show-dependencies - c1 | dot -Tsvg:cairo -o graph.svg
    > cbr comp dot --show-facets - c1 | dot -Tsvg:cairo -o graph.svg
    > cbr comp dot --show-dependencies --show-facets - c1 | dot -Tsvg:cairo -o graph.svg
    > rake
    > ls doc

* See in-place run scripts for ruby.

    > cbr bin run - c1 c2_prog

* Cabar as component

    > (cd .. && CABAR_PATH=@. bin/cbr comp list)
    > (cd .. && CABAR_PATH=@. bin/cbr run - cabar cbr list) 

* cbr-run on a #! line.

    > cbr-run-test

