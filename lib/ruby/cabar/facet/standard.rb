require 'cabar/facet'


module Cabar
  class Facet

    # Expands String in context of the Facet's Component.
    # FIXME: Move to facet.rb?
    def expand_string str
      return str unless String === str
      if str =~ /\#\{/
        str = '"' + str.sub(/[\\\"]/){|x| "\\#{x}"} + '"'
        component.instance_eval(str)
      else
        str
      end
    end

    def is_env_var?
      false
    end

    # This represents a set of environment variables.
    #
    #   facet:
    #     env:
    #       NAME1: v1
    #       NAME2: v2
    #
    # This decomposes itself into EnvVar Facets in
    # attach_component! method.
    class EnvVarGroup < self
      # Hash of environment variables.
      attr_accessor :vars

      def _reformat_options! opts
        opts = { :vars => opts }
        opts
      end

      def compose_facet! facet
        self
      end

      # Creates individual EnvVar facets for each
      # key/value pair in the option Hash.
      def attach_component! c
        vars.each do | n, v |
          $stderr.puts "   env: #{n} #{v}"
          c.create_facet(:env_var, { :env_var => n, :value => v })
        end
      end
    end # class

    # A basic environment variable facet.
    class EnvVar < self
      # The name of this environment variable.
      attr_accessor :env_var

      # The current value for this environment variable.
      attr_accessor :value

      def env_var= x
        @env_var = x && x.to_s
        x
      end

      def is_env_var?
        ! ! @env_var
      end

      COMPONENT_ASSOCATIONS = [ 'provides'.freeze, 'environment'.freeze ].freeze
      def component_associations
        COMPONENT_ASSOCATIONS
      end

      # This will set the environment variable value,
      # If not already set.
      def compose_facet! facet
        value = facet.value 
        if @value == nil || @value == value
          @value = value 
          @setter ||= facet.component
        else
          raise "EnvVar #{env_var.inspect} already set to #{@value.inspect} by #{@setter.inspect}"
        end

        self
      end

      # Renders this environment variable's value.
      #
      # FIXME: This should be refactored to the render as
      # render_Path.
      def render r
        r.setenv(env_var, expand_string(value))
      end

      def to_a
        super +
          [
           [ :env_var, env_var ],
           [ :value, value ],
          ]
      end
    end


    # A facet that represents a directory search path.
    #
    # If env_var is set,
    # it can be compose an environment variable
    # from paths in many components.
    #
    # Used for composing PATH, RUBYLIB, PERL5LIB
    # environment variables to reintegrate modules
    # and programs.
    class Path < self
      # The standard path for instances of this Facet prototype.
      # Defaults to the Facet's key.
      attr_accessor :std_path

      # The array of paths relative to the Component's base_directory.
      attr_accessor :path
     
      # The absolute path names for each element in path.
      attr_accessor :abs_path

      # The environment variable associated with this Facet.
      # If set, is_env_var? is true and
      # this Facet is composable in Context#compose_facets.
      attr_accessor :env_var

      # If set, the generated abs_path will
      # have [ x, "#{x}/#{arch_dir}" ] for
      # each element x in path.
      attr_accessor :arch_dir


      COMPONENT_ASSOCIATIONS = [ 'provides' ].freeze
      COMPONENT_ASSOCIATIONS_ENV_VAR = [ 'provides', 'environment' ].freeze
      def component_associations
        if is_env_var?
          COMPONENT_ASSOCIATIONS_ENV_VAR
        else
          COMPONENT_ASSOCIATIONS
        end
      end

      def env_var= x
        @env_var = x && x.to_s
        x
      end

      def is_env_var?
        ! ! @env_var
      end

      def deepen_dup!
        super
        @path = @path.dup rescue @path
        @abs_path = @abs_path.dup rescue @abs_path
      end

      # Returns std_path or the Facet prototype key.
      def default_path
        [ (std_path || key).to_s ]
      end

      # This Facet is inferred if each element in abs_path
      # exists on the file system.
      def inferred?
        p = abs_path
        p && p.all? { | x | File.exist? x }
      end

      # Returns the path.  If not set, default_path is used.
      def path
        @path ||= 
          default_path
      end

      # Returns the architecture-specific subdirectory.
      # If arch_dir is a Proc, it is called with self.
      #
      # See cabar/plugin/ruby.rb for an example.
      def arch_dir_value
        case @arch_dir
        when Proc
          @arch_dir.call(self)
        else
          @arch_dir
        end
      end

      def uncache_abs_path!
        @abs_path = nil
      end

      # Calculates the absolute path of each element in path.
      # arch_dir subdirectories are interpolated on each element, if
      # they exist.
      def abs_path
        @abs_path ||= 
        owner &&
        begin
          @abs_path = EMPTY_ARRAY # recursion lock.

          x = path.map { | dir | File.expand_path(expand_string(dir), owner.base_directory) }

          arch_dir = arch_dir_value
          if arch_dir
            # arch_dir = [ arch_dir ] unless Array === arch_dir
            x.map! do | dir |
              if File.directory?(dir_arch = File.join(dir, arch_dir))
                dir = [ dir, dir_arch ]
                # $stderr.puts "  arch_dir: dir = #{dir.inspect}"
              end
              dir
            end
            x.flatten!
            # $stderr.puts "  arch_dir: x = #{x.inspect}"
          end

          @abs_path = x
        end
      end

      # FIXME: This should be refactored to the render as
      # render_Path.
      def render r
        if is_env_var?
          r.setenv(env_var, abs_path.uniq.join(r.path_sep))
        end
      end

      # Returns abs_path joined with the standard path separator.
      def value
        abs_path.uniq.join(Cabar.path_sep)
      end

      # This will append the other Facet's abs_path to this
      # Facet's abs_path uniquely.
      def compose_facet! facet
        # At this time: arch_path usage in abs_path should be resolvable.
        # facet.uncache_abs_path!
        @abs_path = (abs_path + facet.abs_path).uniq
        #if @key == 'cnu_config_path'
        #  $stderr.puts "compose_facet! #{@key.inspect}\n  owner = #{@owner}\n  abs_path = #{@abs_path.inspect}"
        #end
        self
      end

      def to_s
        "#<#{self.class} #{key.inspect} #{env_var.inspect} #{path.inspect}>"
      end

      def inspect
        to_s
      end
 
      def to_a
        x = super
        x.push [ :env_var, env_var ] if env_var
        x.push [ :path, path ]
        x.push [ :abs_path, abs_path ]
        x
      end
    end


    # Represents a component that recursively contains other components.
    #
    # Cabar itself uses this Facet, to provide standard
    # software platform components, e.g.: Ruby, Perl and Rubygems.
    #
    # See cabar/comp in the source distribution.
    class Components < Path
      def component_associations
        [ 'provides' ]
      end

      # This Facet must be configured early, because
      # it affects the component search path and
      # loading of other components.
      def configure_early?
        true
      end

      # Addes its subcomponent directories to
      # the current Cabar::Loader.component_search_path,
      # thus forcing its components to become visible.
      # 
      # Cabar itself uses this Facet, to provide standard
      # software platform components, e.g.: Ruby, Perl and Rubygems.
      #
      # See cabar/comp in the source distribution.
      def attach_component! c
        super
        # $stderr.puts "adding component search path #{abs_path.inspect}"
        c.context.loader.add_component_search_path! abs_path
      end
    end # class

  end # class

end # module


require 'cabar/facet/required_component'


