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


      # Renders a Resolver object,
      # Using the Resolver's current required_components_dependencies.
      #
      def render_Resolver resolver
        comment "Cabar Resolver Environment"

        comps = resolver.required_component_dependencies
        
        self.env_var_prefix = "CABAR_"
        setenv "TOP_LEVEL_COMPONENTS", resolver.top_level_components.map{ | c | c.name }.join(" ")
        
        setenv "REQUIRED_COMPONENTS", comps.map{ | c | c.name }.join(" ")

        render_facets_map resolver.facets

        render comps

        render resolver.facets.values
        
        render_configuration_env_var resolver.configuration
      end
      

      def render_facets_map facets
        facets = facets.values if Hash === facets

        self.env_var_prefix = "CABAR_"
        comment nil
        comment "Cabar Facets"
        setenv "PATH_SEP", Cabar.path_sep
        setenv "FACETS", facets.map{ | f | f.key.to_s }.sort.join(",")
        setenv "FACET_ENV_VAR_MAP", facets.select{ | f | f.env_var }.map{ | f | "#{f.key}=#{f.env_var}" }.sort.join(',')
      end


      def render_Selection selection
        if _options[:selected]
          comment "Cabar Selection Environment"
          setenv "SELECTED_COMPONENTS", selection.map{ | c | c.name }.join(" ")

          render_facets_map selection.resolver.facets

          render selection.to_a

          render_configuration_env_var selection.resolver.configuration
        else
          render selection.resolver
        end
      end


      def render_Array_of_Component comps, opts = EMPTY_HASH
        comment nil
        comment "Cabar Component Environment"

        comps.each do | c |
          comment nil
          comment "Cabar component #{c.name}"
          self.env_var_prefix = "CABAR_#{c.name}_"
          setenv :NAME, c.name
          setenv :VERSION, c.version
          setenv :DIRECTORY, c.directory
          setenv :BASE_DIRECTORY, c.base_directory
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
      end


      def render_Array_of_Facet facets, opts = EMPTY_HASH
        comment nil
        comment "Cabar Facet Environment"        
        self.env_var_prefix = ''
        facets.each do | facet |
          comment nil
          comment "facet #{facet.key.inspect} owner #{facet.owner}"
          facet.render self
        end
      end


      # render configuration.env_var
      def render_configuration_env_var configuration
        comment nil
        comment "Cabar Configuration Environment"
        configuration.env_var.each do | k, v |
          setenv k, v
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
      

      def normalize_env_name name
        name = name.to_s.gsub(/[^A-Z0-9_]/i, '_')
      end


      # Render a basic environment variable set.
      def setenv name, val
        name = normalize_env_name name
        name = name.to_s
        val = val.nil? ? val : val.to_s
        if env_var_prefix == ''
          _setenv "CABAR_ENV_#{name}", val
        end
        _setenv "#{env_var_prefix}#{name}", val
      end


      # Renders low-level environment variable set.
      # If val is nil, the environment variable is unset.
      # Subclass should override this.
      def _setenv name, val
        # NOTHING
      end
      
    end # class

    
    # Renders environment variables directly into
    # this Ruby process.
    #
    # $: is modified if RUBYLIB is defined.
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

      # Note renders RUBYLIB directly into $:.
      def _setenv name, val 
        if verbose
          $stderr.puts "# #{$0} setenv #{name.inspect} #{val.inspect}"
        end
        name = normalize_env_name name
        if (v = @env[name]) && ! @env[save_name = "CABAR_BEFORE_#{name}"]
          @env[save_name] = v
        end
        if val == nil
          @env.delete(name)
        else
          @env[name] = val
        end

        if name == 'RUBYLIB' && @env.object_id == ENV.object_id && val != nil
          $:.clear
          $:.push(*Cabar.path_split(val))
          # $stderr.puts "Changed $: => #{$:.inspect}"
        end
      end
    end # class


    # Renders environment variables as a sourceable /bin/sh shell script.
    class ShellScript < EnvVar
      def _setenv name, val 
        name = normalize_env_name name
        if val == nil
          puts "unset #{name};"
        else
          puts "#{name}=#{val.inspect}; export #{name};"
        end
      end
    end # class

    
    # Renders environment variables as Ruby code.
    class RubyScript < EnvVar
      def _setenv name, val
        name = normalize_env_name name
        if val == nil
          puts "ENV.delete(#{name.inspect});"
        else
          puts "ENV[#{name.inspect}] = #{val.inspect};"
        end
      end
    end # class


  end # class
  
end # module


# TODO: Remove when clients expliclity require this module.
require 'cabar/renderer/yaml'
