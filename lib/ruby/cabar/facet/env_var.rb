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
    end # class

   end # class

end # module



