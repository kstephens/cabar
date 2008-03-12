require 'cabar/facet'

require 'cabar/version'


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
    #attr_accessor :name
    attr_accessor_type :version, Cabar::Version
    #attr_accessor :directory
    attr_accessor :base_directory
    
    # Associations.
    
    # The Context object.
    attr_accessor :context

    # A list of all Facets in the Component.
    attr_reader :facets
    
    # All the provides Facets.
    attr_reader :provides
    
    # All the requires components.
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

    
    def initialize *args
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
      @base_directory ||= directory
    end
    
    # Returns true if the Component is top-level.
    def top_level?
      o = _options
      o[:top_level]
    end

    # Returns true if the Component is enabled.
    def enabled?
      o = _options
      o[:enabled].nil? || o[:enabled]
    end
    
    def append_configuration! conf
      conf.each do | k, v |
        configuration[k] = v
      end
    end
    
    def validate!
      requires.each do | r |
        r.validate!
      end
    end
    
    def to_s format = :long
      case format
      when :short
        "#{name}/#{version}"
      when :long
        "#{name}/#{version}@#{directory}"
      end
    end
    
    def inspect *args
      to_s(*args).inspect
    end
    
    
    # friend

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
              context.select_component opts
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
        
        (conf['environment'] || EMPTY_HASH).each do | k, v |
          opts = { :var => k, :value => v }
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
        raise("in #{self.inspect}: #{err}\n  #{err.backtrace.join("\n  ")}")
      end
    end
    
    def select_component!
      facets.each do | f |
        f.select_component!
      end
    end
    
    def resolve_component!
      facets.each do | f |
        f.resolve_component!
      end
    end
    
    def require_component!
      facets.each do | f |
        f.require_component!
      end
    end
    
    def add_dependent! dependent
      @dependents << dependent
      context.add_required_component! self
    end
    
    # friend
    
    def has_facet? f
      f = f.key if Facet === f
      @facet_by_key.key? f
    end

    def facet f
      f = f.key if Facet === f
      @facet_by_key[f]
    end

    def attach_facet! f
      return f unless f
      
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
      
      f
    end
    
    
    # Returns a new Facet attached to this Component.
    def create_facet type, conf, opts = EMPTY_HASH, &blk
      f = Facet.create type, conf, opts, &blk
      return f unless f
      
      f.owner = self
      f.context = self.context

      # Attach inferrable Facets only if inferred.
      attach = true
      if opts[:infer] && ! f.infer? 
        attach = false
      end
      unless f.enabled?
        attach = false
      end

      f.attach_component! self if attach 

      f
    end
    
  end # class
  
end # module

