require 'cabar/facet'

require 'cabar/version'
require 'cabar/version/requirement'

module Cabar
  class Facet
    # Represents a component required by another component.
    class RequiredComponent < self
      attr_accessor :name

      attr_accessor :component_type

      attr_accessor_type :version, Cabar::Version::Requirement
      
      # Configuration to apply the resolved Component.
      attr_accessor :configuration
      
      # The resolved Component.
      attr_reader :resolved_component
      
      def initialize *args
        super
        @configuration ||= { }
      end
      
      COMPONENT_ASSOCIATIONS = [ 'requires'.freeze ].freeze
      def component_associations
        COMPONENT_ASSOCIATIONS
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
            # Get constraint options.
            opts = { }
            opts[:name] = name
            opts[:version] = version if version
            opts[:component_type] = component_type if component_type
            opts[:_by] = component

            Cabar::Constraint.create opts
          end
      end
      
      # Returns the resolved Component for this dependency.
      def resolved_component
        @resolved_component ||= 
          begin 
            
            if c = resolver.resolve_component(to_constraint)
              resolved_component!(c, resolver)
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
      def resolved_component! c, resolver
        @resolved_component = c
        c.add_dependent!(self.owner, resolver)
        c.append_configuration! self.configuration

        # This is very ugly.
        resolver.available_components.each do | comp |
          comp.facets.each do | facet |
            facet.component_dependency_resolved!(resolver)
          end
        end
      end
      
      
      # Pass 1:
      # If we can resolve a component now,
      # ask it to select it's dependencies.
      def select_component! resolver
        super
        
        return if @_select_component
        @_select_component = true
        
        resolver.select_component to_constraint
        
        if r = resolved_component
          resolver._require_component(r)
        end
      end
      
      # Pass 2: attempt to resolve unique version
      # if not already resolved.
      def resolve_component! resolver
        super
        
        return if @_resolve_component
        @_resolve_component = true
        
        if c = resolved_component
          c.select_component! resolver
        end
      end
      
      # Pass 3: select latest component version
      # if not already resolved.
      def require_component! resolver
        super
        
        return if @_require_component
        @_require_component = true
        
        unless resolved_component
          if c = resolver._require_component(to_constraint) 
            @resolved_component = c
          else
            resolver.
              unresolved_component!(
                                    :name => name, 
                                    :component_type => component_type,
                                    :version => version, 
                                    :dependent => component
                                    )
          end
        end
      end
      
      # Will fail of dependency cannot be resolved.
      def validate! resolver
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
           [ :component_type, "#{c && c.component_type}" ],
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
