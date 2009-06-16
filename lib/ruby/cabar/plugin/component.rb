

Cabar::Plugin.new :name => 'cabar/component', :documentation => 'Component support.' do

  require 'cabar/renderer/dot'     # Dot graph support.

  facet :required_component, :class => Cabar::Facet::RequiredComponent
  
  cmd_group [ :component, :comp, :c ] do
    doc "[ --verbose ] 
Lists all available components."
    cmd [ :list, :ls ] do
      selection.select_available = true

      yaml_renderer.
        render(selection.to_a,
               :sort => true
               )
    end

    doc "
Show the facets for the top-level component."
    cmd :facet do
      selection.select_required = true

      yaml_renderer.
        render(context.
               facets.
               values
               )
    end
    
    doc "[ <graph-options> ... ]
Render the components as a Dot graph on STDOUT.
See http://www.graphvis.org/ for more information about Dot.

Example Usage:

  cbr comp dot -r component | dot -Tsvg -o graph.svg

Graph Options:
#{Cabar::Renderer::Dot.command_documentation}"
    cmd :dot do
      context.unresolved_components_ok!
      selection.select_available = true

      if opt = cmd_opts[:r]
        context.require_component(Cabar::Constraint.create(opt))
        context.resolve_components!
      end

      r = Cabar::Renderer::Dot.new cmd_opts
      r.components = selection.to_a

      r.render(context)
    end
    
    doc "[ <cmd-opts???> ]
Lists the dependencies for a selected component."
    cmd :dependencies do
      selection.select_required = true
      selection.select_dependencies = true

      yaml_renderer.
        render(selection.to_a)
    end

    doc "[ <cmd-opts???> ]
Lists the current settings for required components."
    cmd :show do
      selection.select_required = true
      selection.to_a # FIXME: needed for required_components below!

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


