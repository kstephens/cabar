require 'cabar/base'


module Cabar

  # Base class for rendering methods of Components and Facets.
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

    # Does multimethod dispatching based on first argument
    # class name.
    def render x, *args
      x.class.ancestors.each do | cls |
        meth = "render_#{cls.name.sub(/^.*::/, '')}" 
        return send(meth, x, *args) if respond_to? meth
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
      return unless verbose 
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

    # Renders environment variables directly into
    # this Ruby process.
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


    # Renders environment variables as a sourceable /bin/sh shell script.
    class ShellScript < self
      def _setenv name, val 
        puts "#{name}=#{val.inspect}; export #{name};"
      end
    end # class

    
    # Renders environment variables as Ruby code.
    class RubyScript < self
      def _setenv name, val
        puts "ENV[#{name.inspect}] = #{val.inspect};"
      end
    end # class


    # Renders as YAML.
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

      def render_components comps, opts = EMPTY_HASH
        render_header
        puts "  component: "
        comps.
        sort { | a, b | 
          (x = a.name <=> b.name) != 0 ? x :
          (x = b.version <=> a.version) != 0 ? x :
          0
        }.
        each do | c |
          render c, opts
        end
      end
      
      def render_facets facets, opts = EMPTY_HASH
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
          puts "    description:   #{c.description.inspect}" if c.description
          puts "    directory:     #{c.directory.inspect}"
          puts "    base_dir:      #{c.base_directory.inspect}" if c.base_directory != c.directory
          puts "    facet:         [ #{c.provides.map{|x| x.key.inspect}.sort.join(', ')} ]"
          puts "    requires:      [ #{c.requires.map{|x| "#{x.name}/#{x.version}".inspect}.sort.join(', ')} ]"
          puts "    configuration: #{c.configuration.inspect}" if ! c.configuration.empty?
          puts "    plugins:       #{c.plugins.map{|p| p.name}.inspect}" if ! c.plugins.empty?
          render_facets c.facets, :indent => '  ' if _options[:show_facet]
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

