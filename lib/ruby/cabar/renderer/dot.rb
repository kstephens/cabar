require 'cabar/renderer'


module Cabar

  class Renderer

    # Renders as a dot graph.
    # See http://www.graphviz.org/
    class Dot < self
      attr_accessor :show_dependencies
      attr_accessor :show_facets
      attr_accessor :show_facet_names
      attr_accessor :show_facet_links
      attr_accessor :show_unrequired_components
      attr_accessor :show_all

      def initialize *args
        @show_dependencies = true
        @show_facets = false
        @show_facet_names = false
        @show_facet_links = false
        @show_unrequired_components = false

        super

        @show_facet_links &&= @show_facets
        if @show_all
          @show_dependencies =
          @show_facets =
          @show_facet_names =
          @show_facet_links =
          @show_unrequired_components =
            true
        end

        @dot_name = { }
        @dot_label = { }
        @current_directory = File.expand_path('.') + '/'
      end

      def render_Context cntx
        @context = cntx

        # Get list of all components.
        components = 
          cntx.
          available_components.to_a.
          sort { |a, b| a.name <=> b.name }

        unless show_unrequired_components
          components = components.select do | c |
            @context.required_component? c
          end
        end

        @components = components

        # Get list of all facets.
        facets =
        components.
        map { | c |
          c.facets
        }.flatten.
        map { | f |
          f._proto
        }.uniq.sort_by{|x| x.key}
        @facets = facets

        puts "digraph Cabar {"
        puts "  overlap=false;"
        puts "  splines=true;"

#        puts ""
#        puts "  // components as nodes"
#        components.each do | c |
#          render c
#        end

        puts ""
        puts "  // component version grouping"
        components.map{ | c | c.name}.uniq.each do | c_name |
          versions = components.select{ | c | c.name == c_name }
          # next if versions.size < 2

          a = versions.first
        
          tooltip = "available: " + versions.sort.reverse.map{|v| v.version.to_s }.join(', ')
          tooltip = tooltip.inspect
          puts "    #{a_name = dot_name a, :version => false} [ shape=box, style=rounded, label=#{"#{c_name}".inspect}, tooltip=#{tooltip} ];"


          puts "  subgraph #{dot_name a, :subgraph => true} {"
          puts "    label=\"\";";
          puts "    color=black;";
 
          versions.each do | c_v |
            render c_v

            b = dot_name c_v
            puts "    #{a_name} -> #{b} [ style=dotted, arrowhead=none ];" 
          end
          puts "  }"

        end

        puts ""
        puts "  // facets as nodes"
        facets.each do | f |
          render f
        end

        puts ""
        puts "  // dependencies as edges"
        components.each do | c |
          c.requires.each do | d |
            render_dependency_link d
          end
        end

        puts ""
        puts "  // facet usages as edges"
        components.each do | c |
          c.facets.each do | f |
            render_facet_link c, f
          end
        end

        puts ""
        puts "// END"
        puts "}"
      end

      def required? c
        @context.required_component? c
      end

      def render_Component c
        # $stderr.puts "render_Component #{c}"
        required = required? c
        style = "solid"
        style = "dotted" unless required
        tooltip = (c.description || c.to_s(:short)).inspect
        puts "  #{dot_name c} [ shape=box, label=#{dot_label c}, tooltip=#{tooltip}, style=#{style}, URL=#{('file://' + c.directory).inspect} ];"
      end

      def render_Facet f
        # $stderr.puts "render_Facet #{f.class}"
        return unless show_facets
        return if Cabar::Facet::RequiredComponent === f
        puts "  #{dot_name f} [ shape=hexagon, label=#{dot_label f} ];"
      end

      def render_dependency_link d
        return unless show_dependencies

        c1 = d.component
        c2 = d.resolved_component

        return unless c1 && c2 &&
          @components.include?(c1) &&
          @components.include?(c2)

        puts "  #{dot_name c1} -> #{dot_name c2} [ label=#{dot_label d}, arrowhead=open ];"
        puts "  #{dot_name c1} -> #{dot_name c2, :version => false} [ style=dotted, arrowhead=open ];"
      end

      def render_facet_link c, f
        return if Cabar::Facet::RequiredComponent === f
        return unless show_facet_links
        puts "  #{dot_name c} -> #{dot_name f} [ style=dotted, arrowhead=none ];"
      end

      # Returns the dot node or edge name for an object.
      def dot_name x, opts = EMPTY_HASH
        @dot_name[[ x, opts ]] ||=
          case x
          when Cabar::Component
            prefix = ''
            if opts[:subgraph]
              opts[:version] = false
              prefix = "SG "
            end

            prefix +
            case opts[:version]
            when false
              "C #{x.name}"
            else
              "C #{x.name} #{x.version}"
            end
          when Cabar::Facet
            "F #{x.key}"
          else
            "X #{x}"
          end.
          inspect
      end


      # Returns the dot node or edge label for an object.
      def dot_label x, opts = EMPTY_HASH
        @dot_label[[x, opts]] ||=
          case x
          when Cabar::Component
            # * name and version
            # * directory
            # * facets (optional)
            dir = x.directory.sub(/^#{@current_directory}/, './')
            str = ''
            str << "#{x.name}"
            str << " #{x.version}" if opts[:version] != false
            str << "\\n#{dir}"
            if show_facet_names && opts[:show_facet_names] != false
              str << "\\n"
              x.provides.map{|f| f.key}.sort.each{|f| str << "<- #{f}\\l"}
              x.plugins.each{|p| str << "<* #{p.name}\\l"}
              # x.plugins.each{|p| p.facets.each{|f| str << "+ #{f}\\l"}}
            end
            '"' + str + '"'
          when Cabar::Facet::RequiredComponent
            # Use the version requirement.
            x._proto ? "#{x.version}".inspect : x.key.to_s.inspect
          when Cabar::Facet
            # Use the facet name.
            x.key.to_s.inspect
          else
            x.to_s.inspect
          end
      end

    end # class

  end # class
  
end # module

