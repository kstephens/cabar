require 'cabar/base'

require 'cabar/facet'

require 'cabar/version'
require 'cabar/observer'


module Cabar
  # Represents a Component that can be composed into a system
  # using Facets to describe how to compose it.
  #
  # A Component resides in a component repository.
  # Multiple component repositories can be searched by specifying
  # CABAR_PATH environment variable.
  #
  # Components are located by the searching the component
  # repositories with the following pattern:
  # 
  #   */cabar.yml
  #   */*/cabar.yml
  #
  # For example:
  #
  #   my_component/cabar.yml
  #   my_component/1.1/cabar.yml
  #   my_component-1.2/cabar.yml
  # 
  # A component cabar.yml file is a the manifest for the component.
  # It has the following major sections:
  # 
  # * component - defines the component(s) that this directory defines.
  # * facets - specifies the facets that this component provides.
  # * requires - specifies the components that this component depends on.
  #
  # For example, a my_component/1.2/cabar.yml:
  #
  #   cabar:
  #     version: v1.0
  #     component:
  #       name: my_component
  #       version: v1.2
  #       description: "My first component"
  #     facet:
  #       bin: true
  #       lib/ruby: true
  #     requires:
  #       ruby: v1.8.6
  #
  # This component depends on ruby 1.8.6 and has a bin directory containing
  # executables and a library of ruby modules.
  #
  class Component < Base
    include Cabar::Observer::Observed

    # The name of this component.
    attr_accessor :name

    # The type of component, defaults to 'cabar'
    attr_accessor :component_type

    # The component version.
    attr_accessor_type :version, Cabar::Version

    #attr_accessor :directory
    attr_accessor :base_directory
    
    # Associations.
    
    # The Resolver object.
    attr_accessor :resolver

    # A list of all Facets in the Component.
    attr_reader :facets
    
    # All the provides Facets.
    attr_reader :provides
    
    # All the RequiredComponent Facets.
    attr_reader :requires
    
    # Computed
    
    # Components that depend on this Component.
    attr_reader :dependents
    
    # General enviroment variables for this Component.
    attr_reader :environment
    
    # General configuration settings for this Component.
    attr_accessor :configuration
    
    # Array of plugins defined by this component.
    attr_accessor :plugins

    # The temporary configuration Hash.
    attr_accessor :_config
    

    # Sorts a collection of Components by name then by reverse version.
    def self.sort comps
      comps.
        sort do | a, b | 
        case
        when (x = a.name <=> b.name) != 0 
          x
        when (x = b.version <=> a.version) != 0
          x
        else
          0
        end
      end
    end

    def self.current
      @@current
    end

    def as_current 
      current_save = @@current
      @@current = self
      yield
    ensure
      @@current = current_save
    end

    
    # The CABAR type.
    CABAR_STR = 'cabar'.freeze

    def initialize *args
      @component_type = CABAR_STR

      @plugins = [ ]
      super
      
      # See component_associations.
      @facets = [ ]
      @facet_by_key = { }

      @provides = [ ]
      @requires = [ ]
      @environment = [ ]
      
      # Computed
      @dependents = [ ]
      @configuration = { }
    end
    
    def deepen_dup!
      super
      @facets = [ ]
      @dependents = [ ]
      @configuration = { }
      self
    end
    
    def plugins= x
      @plugins = x
      x.each { | x | x.component = self }
      x
    end

    # Returns the base directory for facet artifacts.
    def base_directory
      @base_directory ||=
        directory
    end
    
    # Returns true if the Component is top-level.
    # Top-level components are automatcially required at top-level.
    def top_level?
      o = _options
      o[:top_level]
    end

    # Returns true if the Component is enabled.
    def enabled?
      o = _options
      o[:enabled].nil? || o[:enabled]
    end

    # Returns true if the Component's status is complete.
    # This can be used to stub components for future use.
    #
    # Incomplete components:
    # * cannot contribute Facet composition,  e.g. do not
    # add bin/ directories to PATH.
    # * are rendered grey in Dot graphs.
    #
    def complete?
      (x = status).nil? || x == 'complete'
    end

    # Called when configuration is applied to a Component
    # from a Facet.
    def append_configuration! conf
      notify_observers :before_append_configuration!, conf
      conf.each do | k, v |
        configuration[k] = v
      end
      notify_observers :after_append_configuration!, conf
      self
    end
    
    def validate! resolver
      requires.each do | r |
        r.validate! resolver
      end
    end
    
    # Returns a Constraint object that exactly matches
    # this Component.
    def to_constraint
      @to_constraint ||=
        Cabar::Constraint.create(:name => name,
                                 :version => version,
                                 :component_type => component_type
                                 )
    end

    # Convert to a String representation that
    # is similar to a Constraint String representation.
    def to_s format = :long
      s = ''

      s << "#{component_type}:" if component_type != CABAR_STR

      s << "#{name}/#{version}"
      case format
      when :long
        s << "@#{directory}" if directory
      end

      s
    end
    
    def inspect *args
      to_s(*args).inspect
    end
    
    
    # friend

    # Called to give some facets an opportunity to add functionality
    # before other Componets are fully parsed from configuration.
    # E.g.: the 'components' Facet changes component_search_path to
    # allow recursive components.
    def parse_configuration_early! conf = self._config
      (conf['facet'] || conf['provides'] || conf['provide'] || EMPTY_HASH).each do | k, opts |
        f = create_facet k, opts, :early => true
      end

      self
    end

    def parse_configuration! conf = self._config
      return if @configured
      @configured = true
      
      # $stderr.puts "configuring #{self._config_file}"

      @_config = nil
      
      # Keep track of which facets are declared to be non-inferrable.
      non_inferrable = { }

      begin
        (conf['facet'] || conf['provides'] || conf['provide'] || EMPTY_HASH).each do | k, opts |
          # $stderr.puts "k = #{k.inspect} #{opts.inspect}"
          f = create_facet k, opts

          # Do not inferr disabled Facets.
          if ! f || (! f.inferrable? || ! f.enabled?)
            non_inferrable[k] = true
          end
        end
        
        # Select specific component version.
        # Does not imply dependency.
        (conf['select'] || EMPTY_HASH).each do | k, opts |
          case k
          when 'component'
            v.each do | name, opts |
              opts[:name] ||= name
              resolver.select_component opts # FIXME
            end
          end
        end
        
        # Handle component dependencies.
        (conf['depend'] || conf['requires'] || conf['require'] || EMPTY_HASH).each do | k, v |
          case k
          when 'component'
            k = :required_component
            unless v
              puts "k = #{k.inspect} v = #{v.inspect}"
            end
            v.each do | name, opts |
              f = create_facet k, opts do | opts, facet |
                opts[:name] ||= name
              end
            end
          else
            raise("unknown requires type #{k.inspect}")
          end
        end
        
        # Handle explicit environment variables.
        (conf['environment'] || EMPTY_HASH).each do | k, v |
          opts = { :env_var => k, :value => v }
          # $stderr.puts "environment #{opts.inspect}"
          f = create_facet :env_var, opts
        end

        # Infer other facets.
        Facet.prototypes.each do | f |
          next if self.has_facet? f
          next if non_inferrable[f.key]
          next unless f.inferrable?
          # $stderr.puts "- #{self.inspect}: inferring facet #{f.key.inspect}"
          f = create_facet f, EMPTY_HASH, :infer => true
        end

      rescue Exception => err
        raise Error.new("in #{self.inspect}", :error => err)
      end
    end
    
    def select_component! resolver
      facets.each do | f |
        f.select_component! resolver
      end
    end
    
    def resolve_component! resolver
      facets.each do | f |
        f.resolve_component! resolver
      end
    end
    
    def require_component! resolver
      facets.each do | f |
        f.require_component! resolver
      end
    end
    
    # Called when a RequiredComponent facet resolves to
    # this Component; dependent is the Component
    # that depended on this Component.
    def add_dependent! dependent, resolver
      notify_observers :before_add_dependent!, dependent

      @dependents << dependent
      resolver.add_required_component! self

      notify_observers :after_add_dependent!, dependent

      self
    end
    
    # Returns all the immediate Component dependencies.
    #
    # Assumes dependencies have been resolved.
    # See Resolver#resolve_components!
    #
    # See Resolver#component_dependencies for a recursive
    # dependency set.
    def dependencies recursive = nil
      if recursive
        resolver.component_dependencies self # FIXME
      else
        requires.map { |f| f.resolved_component }
      end
    end

    # friend
    
    # Returns true if this Component has a facet by
    # name or prototype.
    def has_facet? f
      f = f.key if Facet === f
      @facet_by_key.key? f
    end

    # Returns the Facet for this Component by name
    # or prototype.
    def facet f
      f = f.key if Facet === f
      @facet_by_key[f]
    end

    # Called when a new facet is attached to this component.
    def attach_facet! f, resolver
      return f unless f

      notify_observers :before_attach_facet!, f

      # Do not bother with disabled Facets.
      return unless f.enabled?

      # Keep all facets
      unless @facets.include? f
        @facets << f
        @facet_by_key[f.key] = f
      end
      
      # Attach to all component attachment points.
      f.component_associations.each do | a |
        a = send(a)
        unless a.include? f
          a << f
        end
      end

      notify_observers :after_attach_facet!, f
      
      f
    end
    
    
    # Returns a new Facet attached to this Component.
    def create_facet type, conf, opts = EMPTY_HASH, &blk
      # $stderr.puts "  create_facet #{type}, #{conf.inspect}, #{opts.inspect}"
      f = Facet.create type, conf, opts, &blk
      return f unless f
      
      f.owner = self
      f.resolver = resolver # FIXME

      # Attach inferrable Facets only if inferred.
      attach = true
      if opts[:infer] && ! f.infer? 
        attach = false
      end
      unless f.enabled?
        attach = false
      end

      f.attach_component!(self, resolver) if attach 

      f
    end
    
  end # class
  
end # module

