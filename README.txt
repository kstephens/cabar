INTRODUCTION:

See lib/perl/cabar.rb for more info.

TO DO:

* Make Cabar::Component not a subclass of Cabar::Facet
* Add support to make Facet auto-discoverable by following facet conventions, such as:
** :key => :bin, :path => 'bin', :_discover => lambda { | f |
* File.directory(f.abs_path) } 

* Add support for component repositories inside components, need
a Facet that appends additional search directories to Cabar::Context.
 
* Add support to default component name and version from component
directory names, such as:
** "foo/1.2/" => { :name => 'foo', :version => '1.2' }
** "foo-1.2/" => { :name => 'foo', :version => '1.2' }
** "foo/" => { :name => 'foo', :version => '0.1' }

Cabar Demo

* Show bin/env.

* List available components.

bin/env cbr list

* Show directory structure.

* Cabar cabar.yml specification.

* Show components and facets:

bin/env cbr show c1

* Show component version selection:

bin/env cbr run c2 c2_prog foo bar

bin/env cbr run c2/1.1 c2_prog foo bar

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

bin/env cbr dot --show-dependencies c1 | dot -Tsvg:cairo -o graph.svg

bin/env cbr dot --show-facets c1 | dot -Tsvg:cairo -o graph.svg

bin/env cbr dot --show-dependencies --show-facets c1 | dot -Tsvg:cairo -o graph.svg

