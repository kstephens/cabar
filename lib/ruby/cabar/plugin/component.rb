


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
[ --verbose ] [ - <component> ]
Lists all available components.
DOC
      yaml_renderer.
        render(context.
               available_components.
               select(search_opts(cmd_args)).
               to_a
               )
    end

    cmd :facet, <<'DOC' do
[ - <component> ]
Show the facets for the top-level component.
DOC
      select_root cmd_args
      
      yaml_renderer.
        render_facets(context.
                      facets.
                      values
                      )
    end
    
    cmd :dot, <<"DOC" do
[ <graph-options> ... ] [ - <component> ]
Render the components as a Dot graph on STDOUT.
See http://www.graphvis.org/ for more information about Dot.

Example Usage:

  cbr comp dot - top_level_component | dot -Tsvg -o graph.svg

Graph Options:
#{Cabar::Renderer::Dot.command_documentation}
DOC
      select_root cmd_args
      
      r = Cabar::Renderer::Dot.new cmd_opts
      
      r.render(context)
    end
    
    cmd :dependencies, <<'DOC' do
[ <cmd-opts???> ] [ - <component> ]
Lists the dependencies for a selected component.
DOC
      root = select_root cmd_args

      yaml_renderer.
        render(context.component_dependencies(root).to_a)
    end

    cmd :show, <<'DOC' do
[ <cmd-opts???> ] [ - <component> ]
Lists the current settings for a selected component.
DOC
      select_root cmd_args
      
      yaml_renderer.
        render(context.required_components.to_a)
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


