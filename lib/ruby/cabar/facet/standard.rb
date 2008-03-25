require 'cabar/facet'


module Cabar
  class Facet

    # This represents a set of environment variables.
    #
    #   facet:
    #     env_var:
    #       NAME1: v1
    #       NAME2: v2
    class EnvVarGroup < self
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
          c.create_facet(:env_var, :env_var => n, :value => v)
        end
      end
    end # class

    def is_env_var?
      false
    end


    # A basic environment variable facet.
    class EnvVar < self
      attr_accessor :env_var

      attr_accessor :value

      def var
        raise ArgumentError
      end
      def var= x
        raise ArgumentError
      end

      def env_var= x
        @env_var = x && x.to_s
        x
      end

      def is_env_var?
        true
      end

      COMPONENT_ASSOCATIONS = [ 'environment'.freeze ].freeze
      def component_associations
        COMPONENT_ASSOCATIONS
      end

      def compose_facet! facet
        value = facet.value 
        if @value == nil || @value == value
          @value = value 
        else
          raise "EnvVar #{env_var.inspect} already set #{@value.inspect}"
        end
        self
      end

      def render r
        r.setenv(env_var, value)
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
      attr_accessor :std_path
      attr_accessor :path
      attr_accessor :abs_path
      attr_accessor :env_var

      def var
        raise ArgumentError
      end
      def var= x
        raise ArgumentError
      end

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
        @env_var
      end

      def deepen_dup!
        super
        @path = @path.dup rescue @path
        @abs_path = @abs_path.dup rescue @abs_path
      end

      def default_path
        [ (std_path || key).to_s ]
      end

      def inferred?
        p = abs_path
        p.all? { | x | File.exist? x }
      end

      def path
        @path ||= 
          default_path
      end

      def abs_path
        @abs_path ||= 
          owner &&
          path.map { | x | File.expand_path(x, owner.base_directory) }
      end

      def render r
        r.setenv(env_var, abs_path.uniq.join(r.path_sep))
      end

      def value
        abs_path.uniq.join(Cabar.path_sep)
      end

      def compose_facet! facet
        @abs_path = (abs_path + facet.abs_path).uniq
        self
      end

      def to_s
        "#<#{self.class} #{key.inspect} #{env_var.inspect} #{abs_path.inspect}>"
      end

      def inspect
        to_s
      end
 
      def to_a
        x = super
        x.puts [ :env_var, env_var ] if @env_var
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


