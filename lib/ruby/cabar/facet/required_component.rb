require 'cabar/facet'

require 'cabar/version'
require 'cabar/version/requirement'

module Cabar
  class Facet
    # Represents a component required by another component.
    class RequiredComponent < self
      # attr_accessor :name
      attr_accessor_type :version, Cabar::Version::Requirement
      
      # Configuration to apply the resolved Component.
      attr_accessor :configuration
      
      # The resolved Component.
      attr_reader :resolved_component
      
      def initialize *args
        super
        @configuration ||= { }
      end
      
      def component_associations
        [ 'requires' ]
      end
      
      def _reformat_options! opts
        case opts
        when true
          opts = { }
        when false
          opts = nil
        when String
          opts = { :version => opts }
        end
        
        opts
      end
      
      # Create a Constraint representing this dependency.
      def to_constraint
        @constraint ||=
          begin
            opts = _options.dup
            opts[:name] = name
            opts[:version] = version if version
            opts[:_by] = component
            Cabar::Constraint.create opts
          end
      end
      
      # Returns the resolved component for this dependency.
      def resolved_component
        @resolved_component ||= 
          begin 
            
            if c = context.resolve_component(to_constraint)
              resolved_component! c
            end
            
            c
          end
      end
      
      # Called when this dependency resolves to
      # a specific component.
      #
      # Notify the resolved component of a dependency.
      #
      # Append additional configuration to the component.
      def resolved_component! c
        @resolved_component = c
        c.add_dependent! self.owner
        c.append_configuration! self.configuration

        # This is very ugly.
        c.context.available_components.each do | comp |
          comp.facets.each do | facet |
            facet.component_dependency_resolved!
          end
        end
      end
      
      
      # Pass 1:
      # If we can resolve a component now,
      # ask it to select it's dependencies.
      def select_component!
        super
        
        return if @_select_component
        @_select_component = true
        
        context.select_component to_constraint
        
        if r = resolved_component
          context._require_component r
        end
      end
      
      # Pass 2: attempt to resolve unique version
      # if not already resolved.
      def resolve_component!
        super
        
        return if @_resolve_component
        @_resolve_component = true
        
        if c = resolved_component
          c.select_component!
        end
      end
      
      # Pass 3: select latest component version
      # if not already resolved.
      def require_component!
        super
        
        return if @_require_component
        @_require_component = true
        
        unless resolved_component
          if c = context._require_component(to_constraint) 
            @resolved_component = c
          else
            context.
              unresolved_component!(
                                    :name => name, 
                                    :version => version, 
                                    :dependent => component
                                    )
          end
        end
      end
      
      # Will fail of dependency cannot be resolved.
      def validate!
        if resolved_component.nil?
          raise("Cannot resolve component for #{self.inspect}") 
        end
      end
      
      def to_a
        c = resolved_component
        super +
          [
           [ :version,   version.to_s ],
           [ :component, "#{c && c.name}/#{c && c.version.to_s}" ],
          ]
      end
      
      def to_s
        "#<#{self.class} #{to_constraint} <= #{component}>"
      end
      
      def inspect
        to_s
      end
    end # class
    
    
  end # class
  
end # module
