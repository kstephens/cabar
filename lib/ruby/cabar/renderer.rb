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


  end # class
  
end # module


# TODO: Remove when clients expliclity require this module.
require 'cabar/renderer/yaml'
