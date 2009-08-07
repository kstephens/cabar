require 'cabar/renderer'


module Cabar

  class Renderer

    # Renders objects as YAML.
    # TODO: make it smarter and leaner.
    class Yaml < self
      attr_accessor :verbose

      def initialize *args
        @verbose = false
        super
      end


      # Only render the header once.
      def render_header
        return if @render_header
        @render_header = 1
        puts Cabar.yaml_header
      end

      def render_Array_of_Component comps, opts = EMPTY_HASH
        render_header
        puts "  component: "

        if opts[:sort]
          comps = Component.sort comps
        end

        comps.each do | c |
          render c, opts
        end
      end
      
      def render_Array_of_Facet facets, opts = EMPTY_HASH
        x = opts[:indent]
        x ||= ''
        render_header
        puts "#{x}  facet: "

        facets = facets.
          sort { | a, b | a.key <=> b.key }

        facets.each do | facet |
          render facet, opts
        end
      end

      def render_Component c, opts = EMPTY_HASH
        if @verbose 
          puts "  - name:          #{c.name.inspect}"
          puts "    version:       #{c.version.to_s.inspect}"
          puts "    enabled:       #{c.enabled?.inspect}"
          puts "    description:   #{c.description.inspect}" if c.description
          puts "    directory:     #{c.directory.inspect}"
          puts "    base_dir:      #{c.base_directory.inspect}" if c.base_directory != c.directory
          puts "    facet:         [ #{c.provides.map{|x| x.key.inspect}.sort.join(', ')} ]"
          puts "    requires:      [ #{c.requires.map{|x| "#{x.name}/#{x.version}".inspect}.sort.join(', ')} ]"
          puts "    configuration: #{c.configuration.inspect}" if ! c.configuration.empty?
          puts "    plugins:       #{c.plugins.map{|p| p.name}.inspect}" if ! c.plugins.empty?
          # puts "    _options:      #{c._options.inspect}"
          render_Array_of_Facet c.facets, :indent => '  ' if _options[:show_facet]
          puts ""
        else
          puts "  - #{[ c.name, c.version.to_s, c.directory ].inspect}"
        end
      end

      def render_Facet facet, opts = EMPTY_HASH
        x = opts[:indent]
        x ||= ''

        case 
        when @verbose
          case
          when opts[:prototype]
            puts "#{x}    #{facet.key}:"
            puts "#{x}      class:       #{facet.class.to_s}"
            puts "#{x}      _defined_in: #{facet._defined_in.to_s.inspect}"
          else            
            a = facet.to_a
            a << [ :_defined_in, facet._defined_in.to_s ]
            puts "#{x}  - " + 
              (a.
               map do | k, v |
                 case v
                 when Hash
                   str = ''
                   v.each do | vk, vv |
                     str << "\n#{x}      #{vk}: #{vv.inspect}"
                   end
                   v = str
                 else
                   v = v.inspect
                 end
                 "#{k}: #{v}"
               end.
               join("\n#{x}    ")
               )
            puts ""
          end
        else
          puts "#{x}  - #{facet.key.inspect}"
        end
      end
      
    end # class

  end # class
  
end # module

