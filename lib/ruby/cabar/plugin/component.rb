


Cabar::Plugin.new :name => 'cabar/component', :documentation => <<'DOC' do
Component support.
DOC

  require 'cabar/command/standard' # Standard command support.
  require 'cabar/facet/standard'   # Standard facets and support.
  require 'cabar/renderer/dot'     # Dot graph support.

  ##################################################################
  # Component commands
  #

  facet :required_component, :class => Cabar::Facet::RequiredComponent
  
  cmd_group [ :component, :comp, :c ] do
    cmd :list, <<'DOC' do
[ --verbose ] 
Lists all available components.
DOC
      selection.select_available = true
      selection.to_a

      yaml_renderer.
        render(selection.to_a,
               :sort => true
               )
    end

    cmd :facet, <<'DOC' do

Show the facets for the top-level component.
DOC
      selection.select_required = true
      selection.to_a

      yaml_renderer.
        render(context.
               facets.
               values
               )
    end
    
    cmd :dot, <<"DOC" do
[ <graph-options> ... ]
Render the components as a Dot graph on STDOUT.
See http://www.graphvis.org/ for more information about Dot.

Example Usage:

  cbr comp dot | dot -Tsvg -o graph.svg

Graph Options:
#{Cabar::Renderer::Dot.command_documentation}
DOC
      selection.select_available = true
      selection.to_a
      
      r = Cabar::Renderer::Dot.new cmd_opts
      r.components = selection.to_a

      r.render(context)
    end
    
    cmd :dependencies, <<'DOC' do
[ <cmd-opts???> ]
Lists the dependencies for a selected component.
DOC
      selection.select_required = true
      selection.select_dependencies = true
      selection.to_a

      yaml_renderer.
        render(selection.to_a)
    end

    cmd :show, <<'DOC' do
[ <cmd-opts???> ]
Lists the current settings for required components.
DOC
      selection.select_required = true
      selection.to_a

      yaml_renderer.
        render(context.required_components.to_a, :sort => true)
      yaml_renderer.
        render(context.facets.values.to_a)
    end
    
  end # cmd_group
  

  ##################################################################
  # Recursive subcomponents.
  #

  facet :components, 
    :class => Cabar::Facet::Components,
    :path => [ 'comp' ],
    :inferrable => true

end # plugin


