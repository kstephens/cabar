require 'cabar/base'


module Cabar
  class Renderer < Base
    attr_accessor :env_var_prefix
    attr_accessor :verbose
    attr_accessor :output
    
    def initialize *args
      @output = $stdout
      super
      @env_var_prefix ||= ''
    end
    
    def path_sep
      Cabar.path_sep
    end

    def puts *args
      @output.puts *args
    end

    def render x
      x.class.ancestors.each do | cls |
        meth = "render_#{cls.name.sub(/^.*::/, '')}" 
        return send(meth, x) if respond_to? meth
      end
    end

    def render_Context x
      comment "Cabar config"
    
      self.env_var_prefix = "CABAR_"
      setenv "top_level_component", x.top_level_components.map{ | c | c.name }.join(" ")

      setenv "required_components", x.required_components.map{ | c | c.name }.join(" ")
      x.required_components.each do | c |
        comment nil
        comment "Cabar component #{c.name}"
        self.env_var_prefix = "CABAR_#{c.name}_"
        setenv :version, c.version
        setenv :directory, c.directory
        setenv :base_directory, c.base_directory
        c.provides.each do | facet |
          comment nil
          comment "facet #{facet.key.to_s.inspect}"
          facet.render self
        end
        c.configuration.each do | k, v |
          comment "config #{k.to_s.inspect}"
          setenv "CONFIG_#{k}", "#{v}"
        end

      end

      self.env_var_prefix = ''
      comment nil
      comment "Cabar General Environment"

      x.facets.values.each do | facet |
        comment nil
        comment "facet #{facet.key.inspect}"
        facet.render self
      end
    end

    # Low-level rendering.


    def comment str
      if str
        str = str.to_s.gsub(/\n/, "\n#")
        puts "# #{str}"
      else
        puts ""
      end
    end

    def setenv name, val
      name = name.to_s
      val = val.to_s
      if env_var_prefix == ''
        _setenv "CABAR__#{name}", val
      end
      _setenv "#{env_var_prefix}#{name}", val
    end

    def _setenv name, val
      # NOTHING
    end

    class InMemory < self
      def initialize *args
        @env = ENV
        super
      end

      def comment str
        if verbose
          $stderr.puts "# #{$0} #{str}"
        end
      end

      def _setenv name, val 
        if verbose
          $stderr.puts "# #{$0} setenv #{name.inspect} #{val.inspect}"
        end
        if (v = @env[name]) && ! @env[save_name = "CABAR___#{name}"]
          @env[save_name] = v
        end
        @env[name] = val

        if name == 'RUBYLIB' && @env.object_id == ENV.object_id
          $:.clear
          $:.push *val.split(Cabar.path_sep)
          # $stderr.puts "Changed $: => #{$:.inspect}"
        end
      end
    end # class


    class ShellScript < self
      def _setenv name, val 
        puts "#{name}=#{val.inspect}; export #{name};"
      end
    end # class

    
    class RubyScript < self
      def _setenv name, val
        puts "ENV[#{name.inspect}] = #{val.inspect}"
      end
    end # class


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
        puts "cabar:"
        puts "  version: #{Cabar.version.to_s.inspect}"
      end

      def render_components comps
        render_header
        puts "  component: "
        comps.
        sort { | a, b | 
          (x = a.name <=> b.name) != 0 ? x :
          (x = b.version <=> a.version) != 0 ? x :
          0
        }.
        each do | c |
          render_component c
        end
      end
      
      def render_component c
        if @verbose 
          puts "  - name:          #{c.name.inspect}"
          puts "    version:       #{c.version.to_s.inspect}"
          puts "    description:   #{c.description.inspect}" if c.description
          puts "    directory:     #{c.directory.inspect}"
          puts "    base_dir:      #{c.base_directory.inspect}" if c.directory != c.base_directory
          puts "    facet:         [ #{c.provides.map{|x| x.key.inspect}.sort.join(', ')} ]"
          puts "    requires:      [ #{c.requires.map{|x| "#{x.name}/#{x.version}".inspect}.sort.join(', ')} ]"
          puts "    configuration: #{c.configuration.inspect}"
          render_facets c.facets, '  ' if _options[:show_facet]
        else
          puts "  - #{[ c.name, c.version.to_s, c.directory ].inspect}"
        end
      end

      def render_facets facets, x = ''
        render_header
        puts "#{x}  facet: "

        facets = facets.
          sort { | a, b | a.key <=> b.key }

        if @verbose
          facets.each do | facet |
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
          end
        else
          facets.each do | facet |
            puts "#{x}  - #{facet.key.inspect}"
          end
        end

      end
      
    end # class


    class DotGraph < self
      attr_accessor :show_dependencies
      attr_accessor :show_facets
      attr_accessor :show_facet_links

      def initialize *args
        @show_dependencies = false
        @show_facets = false
        super
        @dot_name = { }
        @dot_label = { }
        @current_directory = File.expand_path('.') + '/'
      end

      def render_Context cntx
        @context = cntx

        components = 
          cntx.
          available_components

        facets =
        components.
        map { | c |
          c.facets
        }.flatten.
        map { | f |
          f._proto
        }.uniq.sort_by{|x| x.key}

        puts "digraph Cabar {"

        puts "  // components"
        components.each do | c |
          render c
        end

        puts "  // facets"
        facets.each do | f |
          render f
        end

        puts "  // dependencies"
        components.each do | c |
          c.requires.each do | d |
            render_dependency_link d
          end
        end

        puts "  // facet links"
        components.each do | c |
          c.facets.each do | f |
            render_facet_link c, f
          end
        end

        puts "}"
      end

      def render_Component c
        # $stderr.puts "render_Component #{c}"
        style="solid"
        style="dotted" unless @context.required_component? c
        puts "  #{dot_name c} [ shape=box, label=#{dot_label c}, style=#{style.inspect} ];"
      end

      def render_Facet f
        # $stderr.puts "render_Facet #{f.class}"
        return unless show_facet_links
        return if Cabar::RequiredComponent === f
        puts "  #{dot_name f} [ shape=hexagon, label=#{dot_label f} ];"
      end

      def render_dependency_link d
        return unless show_dependencies
        c1 = d.component
        c2 = d.resolved_component
        puts "  #{dot_name c1} -> #{dot_name c2} [ label=#{dot_label d}, arrowhead=open ];"
      end

      def render_facet_link c, f
        return if Cabar::RequiredComponent === f
        return unless show_facet_links
        puts "  #{dot_name c} -> #{dot_name f} [ style=dotted, arrowhead=none ];"
      end

      def dot_name x
        @dot_name[x] ||=
          case x
          when Cabar::Component
            "#{x.name} #{x.version}".inspect
          when Cabar::Facet
            x.key.to_s.inspect
          else
            x.to_s.inspect
          end
      end


      def dot_label x
        @dot_label[x] ||=
          case x
          when Cabar::Component
            dir = x.directory.sub(/^#{@current_directory}/, '')
            str = "#{x.name} #{x.version}\\n#{dir}"
            if show_facets
              str << "\\n" + x.provides.map{|f| f.key}.sort.map{|f| "* #{f}"}.join("\\l") + "\\l"
            end
            '"' + str + '"'
          when Cabar::RequiredComponent
            x._proto ? "#{x.version}".inspect : x.key.to_s.inspect
          when Cabar::Facet
            x.key.to_s.inspect
          else
            x.to_s.inspect
          end
      end

    end # class

  end # class
  
end # module

