require 'cabar/renderer'


module Cabar

  # Base class for rendering methods of Components and Facets.
  class Renderer

    # Abstract superclass for rendering environment variables.
    class EnvVar < self
      attr_accessor :env_var_prefix

      def initialize *args
        @env_var_prefix ||= ''
        super
      end

      # Calls Cabar.path_sep.
      def path_sep
        Cabar.path_sep
      end

      # Renders a Context object.
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
      
      # Renders a comment if verbose.
      def comment str
        return unless verbose 
        if str
          str = str.to_s.gsub(/\n/, "\n#")
          puts "# #{str}"
        else
          puts ""
        end
      end
      

      # Render a basic environment variable set.
      def setenv name, val
        name = name.to_s
        val = val.to_s
        if env_var_prefix == ''
          _setenv "CABAR__#{name}", val
        end
        _setenv "#{env_var_prefix}#{name}", val
      end

      # Renders low-level environment variable set.
      # Subclass should override this.
      def _setenv name, val
        # NOTHING
      end
      
    end # class

    
    # Renders environment variables directly into
    # this Ruby process.
    class InMemory < EnvVar
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
          $:.push(*Cabar.path_split(val))
          # $stderr.puts "Changed $: => #{$:.inspect}"
        end
      end
    end # class


    # Renders environment variables as a sourceable /bin/sh shell script.
    class ShellScript < EnvVar
      def _setenv name, val 
        puts "#{name}=#{val.inspect}; export #{name};"
      end
    end # class

    
    # Renders environment variables as Ruby code.
    class RubyScript < EnvVar
      def _setenv name, val
        puts "ENV[#{name.inspect}] = #{val.inspect};"
      end
    end # class


  end # class
  
end # module


# TODO: Remove when clients expliclity require this module.
require 'cabar/renderer/yaml'