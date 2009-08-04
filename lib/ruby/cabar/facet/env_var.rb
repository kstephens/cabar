require 'cabar/facet'


module Cabar
  class Facet

    # Most Facets are not environment variables.
    # Mixin for Cabar::Facet::EnvVar.
    def is_env_var?
      false
    end


    # A basic environment variable facet.
    class EnvVar < self
      # The name of this environment variable.
      attr_accessor :env_var

      # The current value for this environment variable.
      attr_accessor :value

      def env_var= x
        @env_var = x && x.to_s.dup.freeze
        @key = :"env_var_#{x}" if x
        x
      end

      def inferrable?
        @env_var && super
      end

      def is_env_var?
        ! ! @env_var
      end


      def validate_facet!
        super
        raise Error, "Facet #{self} does not have an env_var" unless @env_var
      end


      COMPONENT_ASSOCATIONS = [ :provides, :env_var ].freeze
      def component_associations
        COMPONENT_ASSOCATIONS
      end

      # Used by Resolver to compose Facets.
      def composition_key
        @composition_key ||=
          [ 
           :env_var, 
           @env_var || (raise Error, "env_var not set for #{owner}"),
          ].freeze
      end

      # This will set the environment variable value,
      # If not already set.
      def compose_facet! facet
        value = facet.value 
        if @value == nil || @value == value
          @value = value 
          @setter ||= facet.component
        else
          raise Error, "EnvVar #{env_var.inspect}=#{value.inspect} in #{facet.owner} already set to #{@value.inspect} by #{@setter ? @setter.inspect : 'global ENV'}"
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
    end # class

   end # class

end # module



