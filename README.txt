INTRODUCTION:

See lib/ruby/cabar.rb for more info.

TO DO:

* Change Facet.key to Facet._key to avoid collision with future use.

* Change Facet.owner to Facet._owner

* Change Facet.context to Facet._context

* Add support to automatically require top_level components.

Cabar Demo

* Show bin/env.

* List available components.

bin/env cbr list

bin/env cbr list - c2

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

* Show environment:

bin/env cbr env c1

* Show plugins:

prod/cnu_config/1.0/cabar.rb

prod/cnu_locale/1.1/cabar.yml : provides.cnu_config_path

* Show graph:

bin/env cbr dot | dot -Tsvg:cairo -o graph.svg

bin/env cbr dot --show-dependencies - c1 | dot -Tsvg:cairo -o graph.svg

bin/env cbr dot --show-facets - c1 | dot -Tsvg:cairo -o graph.svg

bin/env cbr dot --show-dependencies --show-facets - c1 | dot -Tsvg:cairo -o graph.svg

* Show in-place run scripts for ruby.

bin/env cbr run - c1 c2_prog

* Show cabar as component

CABAR_PATH=.. bin/cbr run - cabar cbr list 

* Show cbr-run on a #! line.

bin/env cbr-run-test
