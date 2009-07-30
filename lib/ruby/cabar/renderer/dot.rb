require 'cabar/renderer'


module Cabar

  class Renderer

    # Renders as a dot graph.
    # See http://www.graphviz.org/
    class Dot < self
      # A list of components to render.
      attr_accessor :components

      @@command_doc = ''
      def self.command_documentation
        @@command_documentation
      end

      @@option_defaults = { }
      def self.command_option name, default, doc
        @@option_defaults[name] = default
        (@@command_documentation ||= '') << "
  --#{name.to_s.gsub('_', '-')} (default #{default.inspect})
#{doc}
"
        attr_accessor name
      end


      command_option :require_selection, false, <<'DOC'
Require all the selected components as top-level.
Expands set of rendered components to all required components.
DOC

      # Options:
      command_option :show_dependencies, true, <<'DOC'
Show dependency edges between components.
DOC

      command_option :show_link_component_versions, false, <<'DOC'
Create links between a node for a component name and each component version.
Also creates links between component versions and a component node.
DOC

      command_option :group_component_versions, false, <<'DOC'
Group component versions in a subgraph.
DOC

      command_option :show_created_from, false, <<'DOC'
Create links between components and their dot['created_from'] attribute.
For example:
  foo/cabar.yml:
    cabar:
      component:
        name: foo
        version: v1.2
        dot:
          created_from: 'bar/1.3'

Will render a <<created-from>> link from foo/1.2 to bar/1.3.

DOC

      command_option :show_component_name, true, <<'DOC'
Show the component name.
DOC

      command_option :show_component_version, true, <<'DOC'
Show the component version.
DOC

      command_option :show_component_directory, false, <<'DOC'
Show the component directory.
DOC

      command_option :show_dependency_constraint, true, <<'DOC'
Show the dependency constraint information on the edge.
DOC

      command_option :show_facets, false, <<'DOC'
Create facets as hexagons.
DOC

      command_option :show_facet_names, false, <<'DOC'
Show facet names as "<- facet" in the component nodes.
DOC

      command_option :show_facet_links, false, <<'DOC'
Create edges between Facets and all components that have them.
DOC

      command_option :show_unrequired_components, false, <<'DOC'
Show unrequired components (components available but not required)
as dotted nodes.
DOC


      command_option :show_all, false, <<'DOC'
Enables every show_* option.
DOC

      command_option :url_transform, false, <<'DOC'
Transforms the file:///... URL links in the dot output using a Ruby expression bound on _

E.g.:
  --url-transform='_.sub(%r{^file:///(.*)}){ "http://somedocsite/$1" }'

DOC

      attr_reader :resolver

      def initialize *args
        @@option_defaults.each do | k, v |
          instance_variable_set("@#{k}", (k.to_s =~ /^show/ ? @show_all : nil)|| v)
        end

        super

        @show_facet_links &&= @show_facets
        if @show_all
          @@option_defaults.each do | k, v |
            instance_variable_set("@#{k}", true)
          end
        end

        @dot_name = { }
        @dot_label = { }
        @required = { } # cache
        @current_directory = File.expand_path('.') + '/'
      end


      # Renders a Resolver as a Dot graph.
      def render_Resolver resolver
        _logger.debug :"Dot#render_Resolver"

        @node_count = 0
        @edge_count = 0

        @resolver = resolver

        available_components = 
          resolver.
          available_components.
          to_a.
          sort { |a, b| a.name <=> b.name }

        # Default selected components to all available components.
        @components ||= available_components

        _logger.info do
          "components specified: #{@components.size}"
        end
        if @components.size < 100
          _logger.info { "components: " }
          _logger.info do
            @components.map{|c| "  " + c.to_s}
          end
        end

        # If --require-selection.
        if require_selection
          @components.each do | x |
            next unless x
            _logger.info { "requiring #{x.class} #{x.inspect}" }
            @resolver.require_component x
          end
          @resolver.resolve_components!
          @components = @resolver.required_components.to_a
        end

        # Get list of components to show.
        @components = @components.
          sort { |a, b| a.name <=> b.name }

        unless show_unrequired_components
          @components = @components.select do | c |
            required? c
          end
        end

        components = @components

        _logger.info do
          "components rendering: #{@components.size}"
        end

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

        # Delay output of edges.
        @edges = [ ]

        puts "// Generated by:"
        puts "//   #$0 #{ARGV.join(' ')}"
        puts "digraph cabar {"
        puts "  overlap=false;"
        puts "  splines=true;"
        puts "  truecolor=true;"
        puts "  clusterrank=local;"

        puts ""
        puts "  // component version grouping"
        components.map{ | c | c.name}.uniq.each do | c_name |
          versions = components.select{ | c | c.name == c_name }
          # next if versions.size < 2

          a = versions.first
          a_name = dot_name a, :version => false

          # Get all versions of
          # component a.
          available_a = 
            available_components.
            select{|c| c.name == a.name }

          if group_component_versions
            # Show all versions available in a tooltip.
            tooltip = "available: " + 
              available_a.
              sort{|a,b| a.version <=> b.version}.
              reverse.
              map{|v| (required?(v) ? '*' : EMPTY_STRING) + v.version.to_s }.join(', ')
            tooltip = tooltip.inspect
            
            # Are any versions of a required?
            any_required = available_a.any?{|c| required? c}
            
            # Make a subgraph of all versions of component a.
            puts ""
            puts "// #{a_name} #{a.name}"
            puts "  subgraph #{dot_name a, :subgraph => true} {"
            puts "    label=#{''.inspect};"
            puts "    style=#{any_required ? :solid : :dotted};"

            if show_link_component_versions
              render_node a_name, 
              :shape => :component,
              :style => [ :rounded, any_required ? :solid : :dotted ], 
              :label => a.name,
              :tooltip => tooltip
            end
          end

          versions.each do | c_v |
            render c_v

            if show_link_component_versions
              render_edge a_name, c_v, 
              :style => :dotted, 
              :arrowhead => :none,
              :comment => "component #{a.name.inspect} version relationship" 
            end
          end

          if group_component_versions
            puts "  }"
            puts ""
          end
        end

        puts ""
        puts "  // facets as nodes"
        facets.each do | f |
          render f
        end

        edge_puts ""
        edge_puts "  // dependencies as edges"
        components.each do | c |
          c.requires.each do | d |
            render_dependency_link d
          end
        end

        edge_puts ""
        edge_puts "  // facet usages as edges"
        components.each do | c |
          c.facets.each do | f |
            render_facet_link c, f
          end
        end

        # Render all edges.
        @edges.each do | e |
          puts e
        end

        puts ""
        puts "// END"
        puts "}"


        _logger.info do
          "nodes: #{@node_count}, edges: #{@edge_count}"
        end
      end


      # Renders a Component as a dot node.
      def render_Component c, opts = nil
        _logger.debug :C, :prefix => false, :write => true

        opts ||= EMPTY_HASH
        # $stderr.puts "render_Component #{c}"

        tooltip = "#{c.to_s(:short)}"
        tooltip << ": #{c.description}" if c.description
        tooltip << "; type: #{c.component_type}" if c.component_type != Component::CABAR_STR

        unless complete?(c)
          tooltip << "; status: #{c.status}"
        end

        opts = {
          :shape => :component,
          :label => dot_label(c),
          :tooltip => tooltip,
          :style => required?(c) ? :solid : :dotted,
          :URL => "file://#{c.directory}",
#          :fillcolor => complete?(c) ? '#ffffff' : '#cccccc',
          :fontcolor => complete?(c) ? '#000000' : '#888888',
          :color     => complete?(c) ? '#000000' : '#888888',
        }

        
        if group_component_versions
          opts[:in_subgraph] = true
        end

        render_node dot_name(c), opts

        render_created_from_link c
      end

      # Renders a Facet as a dot node, if show_facets is enabled.
      def render_Facet f
        # $stderr.puts "render_Facet #{f.class}"
        return unless show_facets
        return if Cabar::Facet::RequiredComponent === f
        _logger.debug :F, :prefix => false, :write => true

        render_node f, 
          :shape => :hexagon, 
          :label => dot_label(f)
      end

      # Renders a dependency link for a given dependency facet.
      def render_dependency_link d
        return unless show_dependencies

        _logger.debug :D, :prefix => false, :write => true

        c1 = d.component
        c2 = d.resolved_component(@resolver)

        return unless c1 && c2 &&
          @components.include?(c1) &&
          @components.include?(c2)

        if show_link_component_versions
          render_edge c1, dot_name(c2, :version => false),
            :tooltip => "depended by: #{c1.name}/#{c1.version}",
            :style => :dotted, 
            :arrowhead => :open,
            :color => complete?(c2) ? '#000000' : '#888888'
        end

        render_edge c1, c2,
          :label => dot_label(d),
          :tooltip => "#{c1.name}/#{c1.version} depends on #{c2.name}/#{c2.version}" + 
            (d.version ? "; requires: #{d.version}" : ''),
          :arrowhead => :vee,
          :style => required?(c1) && required?(c2) ? nil : :dotted,
          :color => complete?(c1) && complete?(c2) ? '#000000' : '#888888'
      end

      # Renders a link between a Component and a Facet.
      def render_facet_link c, f
        return if Cabar::Facet::RequiredComponent === f
        return unless show_facet_links
        _logger.debug :L, :prefix => false, :write => true

        render_edge c, f, :style => :dotted, :arrowhead => :none
      end

      def render_created_from_link c1
        return unless show_created_from

        d = c1.dot
        # $stderr.puts "c = #{c1} c.dot => #{c.dot.inspect}"
        return unless d

        created_from = d['created_from']
        return unless created_from

        # $stderr.puts "c1 = #{c1}"
        # $stderr.puts "  created_from = #{created_from.inspect}"

        created_from = resolver.selected_components[created_from]
        # $stderr.puts "  created_from = #{created_from.inspect}"

        return unless created_from
        return if created_from.empty?
        c2 = created_from.first
        # $stderr.puts "  c2 = #{created_from.inspect}"

        return unless @components.include? c2

        color = complete?(c1) && complete?(c2) ? '#000000' : '#888888'
        render_edge c1, c2, 
        :style => :dotted,
        :arrow_head => :ovee,
        :color => color,
        :fontcolor => color,
        :label => "<<created-from>>",
        :tooltip => "#{c1.to_s(:short)} created from #{c2.to_s(:short)}"
      end

      # Renders a node.
      # If name is not a String, call dot_name() on it.
      def render_node name, opts = nil
        @node_count += 1

        _logger.debug :n, :prefix => false, :write => true

        opts ||= EMPTY_HASH
        name = dot_name(name) unless String === name
        prefix = name
        suffix = EMPTY_STRING

        if true || opts[:in_subgraph]
          opts.delete(:in_subgraph) rescue nil
          prefix = 'node'
          suffix = name
        end

        if opts[:comment]
          edge_puts "    // #{opts[:comment]}"
          opts.delete(:comment)
        end

        if _ = opts[:URL] and url_transform
          # $stderr.puts "_ = #{_.inspect}"
          # $stderr.puts "url_transform = #{url_transform.inspect}"
          begin
            _ = opts[:URL] = eval(url_transform)
            # $stderr.puts "result = #{_.inspect}"
          rescue Exception => err
            $stderr.puts "#{err.inspect}: url_transform #{url_transform.inspect} failed"
          end
        end

        puts "    #{prefix} #{dot_opts opts} #{suffix};"
      end

      # Renders an edge between two nodes.
      # If n1 or n2 are not Strings, call dot_name() on them.
      def render_edge n1, n2, opts = nil
        @edge_count += 1

        _logger.debug :e, :prefix => false, :write => true

        opts ||= EMPTY_HASH

        n1 = dot_name(n1) unless String === n1
        n2 = dot_name(n2) unless String === n2

        if opts[:comment]
          edge_puts "    // #{opts[:comment]}"
          opts.delete(:comment)
        end

        edge_puts "    #{n1} -> #{n2} #{dot_opts opts};"
      end

      # Generate string for dot nodes or edges
      # Nil values are not expanded.
      def dot_opts opts = nil
        opts ||= EMPTY_HASH
        unless opts.empty?
          '[ ' + 
          opts.map do |k, v| 
            unless v.nil? 
              case v
              when Numeric
                v
              when Array
                v = v.compact.join(',').inspect.gsub(/\\\\/, '\\')
              else
                v = v.to_s.inspect.gsub(/\\\\/, '\\')
              end
              "#{k}=#{v}"
            end
          end.compact.join(', ') +
          ' ]'
        else
          EMPTY_STRING
        end
      end

      # Return true if a Component is top-level.
      def top_level? c
        @resolver.top_level_component? c
      end

      # Returns true if a Component is required.
      def required? c
        (
         @required[c.object_id] ||=
         [ @resolver.required_component?(c) ]
         ).first
      end

      # Returns true if a Component is complete.
      def complete? c
        c.complete?
      end

      # Outputs edges.
      def edge_puts x
        if @edges
          @edges << x.to_s
        else
          puts x.to_s
        end
      end

      # Returns the dot node or edge name for an object.
      # Callers should not change opts afterwards.
      def dot_name x, opts = EMPTY_HASH
        @dot_name[[ x, opts ]] ||=
          case x
          when Cabar::Component
            prefix = EMPTY_STRING
            if opts[:subgraph]
              opts[:version] = false
              prefix = "cluster_"
            end

            prefix +
            case opts[:version]
            when false
              "c #{x.name}"
            else
              "c #{x.name} #{x.version}"
            end
          when Cabar::Facet
            "f #{x.key}"
          else
            "x #{x}"
          end.
          # sub(/([a-z]+) (.*)/i){|| "#{$1}_#{$2.hash}"}.
          gsub(/[^a-z_0-9]/i, '_') 
      end


      # Returns the dot node or edge label for an object.
      # Callers should not change opts afterwards.
      def dot_label x, opts = EMPTY_HASH
        @dot_label[[x, opts]] ||=
          case x
          when Cabar::Component
            # * name and version
            # * directory
            # * facets (optional)
            str = ''

            if show_component_name
              str << "#{x.name}"
            else
              str << "#"
            end

            if show_component_version
              str << "/#{x.version}" if opts[:version] != false
            end

            if show_component_directory
              dir = x.directory.to_s.sub(/^#{@current_directory}/, './')
              str << "\n#{dir}"
            end

            if show_facet_names && opts[:show_facet_names] != false
              str << "\n"
              # <- <<exported facet name>>
              x.provides.
                map{|f| f.key}.
                sort.
                each{|f| str << "<- #{f}\\l"}

              # <* <<plugin name>>
              x.plugins.
                map{|p| p.name}.
                sort.
                map{|p| p.sub(/\/.*$/, '/*')}.
                uniq.
                each{|p| str << "<* #{p}\\l"}
            end
            # '"' + str + '"'
            str
          when Cabar::Facet::RequiredComponent
            # Use the version requirement.
            show_dependency_constraint ?
              (x._proto ? x.version.to_s : x.key.to_s) :
              EMPTY_STRING
          when Cabar::Facet
            # Use the facet name.
            x.key.to_s
          else
            x.to_s
          end
      end

    end # class

  end # class
  
end # module

