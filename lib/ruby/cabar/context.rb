require 'cabar/base'

require 'cabar/version'
require 'cabar/version/requirement'
require 'cabar/version/set'
require 'cabar/context'
require 'cabar/renderer'
require 'cabar/facet'
require 'cabar/facet/standard'
require 'cabar/relationship'
require 'cabar/component'
require 'cabar/component/set'

require 'cabar/configuration'
require 'cabar/loader'
require 'cabar/facet'
require 'cabar/observer'
require 'cabar/sort'


module Cabar
  # Manages sets of available, selected, required and unresolved components.
  #
  # Also manages collecting and composing Facets vended from required
  # components.
  class Context < Base
    include Cabar::Observer::Observed
    include Cabar::Sort

    # The Cabar::Main object.
    attr_accessor :main

    # Set of all components availiable.
    attr_reader :available_components

    # Set of all components selected by constraints.
    attr_reader :selected_components

    # Set of all components explicitly required.
    attr_reader :required_components
    
    # Set of top-level components required.
    attr_reader :top_level_components

    # Set of components that are unresolved due to constraints.
    attr_reader :unresolved_components

    def self.current
      @@current
    end
    def self.current= x
      @@current = x
    end
    def make_current!
      Cabar::Context.current = self
    end


    def initialize opts = EMPTY_HASH
      @required_components = Cabar::Version::Set.new
      @top_level_components = [ ] # ordered Cabar::Version::Set.new
      @unresolved_components = { } # name
      super
    end

    def _logger
      @_logger ||= 
        Cabar::Logger.new(:name => :context,
                          :delegate => main._logger
                          )
    end

    # For Facet:: support.
    def base_directory
      @base_directory ||=
        directory
    end

    ###########################################################
    # Configuration
    #

    # Returns the Cabar::Configuration object.
    def configuration
      @configuration ||= 
        Cabar::Configuration.new(:context => self)
    end

    # Returns the configuration hash.
    def config
      configuration.config
    end

    # Returns the entire configuration Hash,
    # including the cabar version header).
    def config_raw
      configuration.config_raw
    end

    # Applies the current configuration to this context.
    def apply_configuration!
      configuration.apply_configuration! self
    end

    # Applies the component requires configuration to this context.
    # This will try CABAR_TOP_LEVEL environment variable
    # first.
    # If not defined, apply the configuration file's
    # component require contraint options.
    def apply_configuration_requires!
      if (x = ENV['CABAR_REQUIRE']) && ! x.empty?
        x = x.split(/\s+/)
        x.each do | constraint |
          require_component constraint
        end
      else
        configuration.apply_configuration_requires! self
      end
    end


    ##################################################################
    # Loading Components.
    #

    # Returns the component loader.
    def loader
      @loader ||= 
        Cabar::Loader.factory.new(:context => self).
        # Prime the component search path queue.
        add_component_search_path!(configuration.component_search_path)
    end

    # Force loading of a component directory.
    # Used to force cabar to load itself.
    def load_component! directory, opts = nil
      loader.load_component!(directory, opts)
    end


    ##################################################################
    # Available Components
    #

    #
    # Returns a set of all available components
    # found through the component directories search path.
    #
    def available_components
      @available_components ||=
        begin
          x = loader.available_components
          _logger.info "available components: #{x.size}"
          x
        end
    end


    ##################################################################
    # Selecting Components
    #

    # Returns the selected component set after
    # applying configuration overrides.
    #
    # The selected component set is used for resolving
    # required components.
    #
    # If a component is over-constrained or unavailable
    # it cannot be required, and an error will be thrown.
    def selected_components
      @selected_components ||=
      begin
        @selected_components = 
          Cabar::Component::Set.new available_components.dup
        
        # Apply the current configuration, such as
        # component version selection and requiring top-level
        # components.
        apply_configuration!

        @selected_components
      end
    end

    # Select a component by constraint.
    # This reduces the selected_components set.
    def select_component opts
      notify_observers :before_select_component, opts

      # $stderr.write 'S'; $stderr.flush

      s = selected_components.select! opts

      notify_observers :after_select_component, opts, s

      s
    end


    ##################################################################
    # Resolving/Requiring Components
    #

    # Returns the component that resolves to the constraint
    # from the selected_components set.
    #
    # If all is true, an Array is returned.
    # If all is false, the resolved component is returned, iff
    # there is no amibiguity.
    def resolve_component opts, all = false
      _logger.debug :r, :write => true, :prefix => false

      c = selected_components.select opts

      case c.size
      when 0
        all ? [ ] : nil
      when 1
        all ? c.to_a : c.first
      else
        all ? c.to_a : nil
      end
    end

    # Requires a specific component and/or version.
    # Adds to top_level_components list.
    def require_component opts
      return nil unless opts

      notify_observers :before_require_component, opts

      c = _require_component opts
      add_top_level_component! c

      notify_observers :after_require_component, opts, c

      c
    end

    # Requires a specific component and/or version.
    # Use internally by cabar during dependency
    # resolution.
    # Does not add component to top_level_components list.
    def _require_component opts
      # $stderr.write 'R'; $stderr.flush

      r = resolve_component opts, :all
      case r.size
      when 0
        constraint = opts
        _logger.error "Cannot find required component #{opts.inspect}"
        opts = opts.to_hash unless Hash === opts
        opts[:dependent] = constraint.to_s
        unresolved_component! opts
        check_unresolved_components
        raise Error, "Cannot find required component #{opts.inspect}"
      else
        # Allow selection of default component.
        # Overlay component defaults.
        name = Hash === opts ? opts[:name] : opts.name
        comp_config = (x = configuration.config['component']) && x['require_default'] || EMPTY_HASH
        comp_config = comp_config[name] || EMPTY_HASH
        comp_config = { :version => comp_config } unless Hash === comp_config

        unless comp_config.empty?
          constraint = opts
          opts = opts.to_hash unless Hash === opts
          opts = opts.cabar_symbolify
          comp_config[:_by] = (opts[:_by].to_s) + " + component:require_default:"
          opts.cabar_merge!(comp_config.cabar_symbolify)
          # $stderr.puts "_require_component default #{opts.inspect} <= #{comp_config}"

          r = resolve_component opts, :all
        end
        
        # Select latest version.
        c = r.first
      end

      # Select the component.
      select_component c

      # Add component as required.
      add_required_component! c

      c
    end


    # Called when a top-level component is required.
    def add_top_level_component! c
      unless @top_level_components.include?(c)
        @top_level_components << c
        notify_observers :add_top_level_component!, c
      end
      c
    end

    # Called when a component is required.
    def add_required_component! c
      unless @required_components.include? c
        @required_components << c
        notify_observers :add_required_component!, c
      end
      c
    end

    # Returns true if a Component is top-level.
    def top_level_component? c
      @top_level_components.include? c
    end

    # Called to resolve all component dependencies:
    # Pass 1: select all components dependencies.
    # Pass 2: resolve all explicit dependencies after selection has been reduced.
    # Pass 3: require the latest dependencies for non-ambigious selections.
    def resolve_components!
      notify_observers :before_resolve_components!

      required_components.each do | c |
        c.select_component!
      end

      required_components.each do | c |
        c.resolve_component!
      end

      required_components.each do | c |
        c.require_component!
      end

      notify_observers :after_resolve_components!

      self
    end
    
    # Returns true if component was required.
    def required_component? c
      @required_components.include? c
    end

    # Called during resolve_compoent!
    def unresolved_component! opts
      opts = opts.to_hash unless Hash === opts
      notify_observers :unresolved_component!, opts
      (@unresolved_components[opts[:name]] ||= [ ]) << opts
      self
    end

    # True if there are unresolved components.
    # This can be due to overconstrained components or
    # components that are unavailable.
    def unresolved_components? 
      ! unresolved_components.empty?
    end

    # Checks unresolved_components list.
    # If there are any, raise an error.
    # 
    # TODO: Make this use the yaml error formatter.
    def check_unresolved_components
      return self unless unresolved_components? 

      notify_observers :before_check_unresolved_components

      msg = ''

      unresolved_components.each do | name, x |
        msg << <<"END"
cabar:
  version: #{Cabar.version.to_s.inspect}
  error:
    message:   "Connot resolve component"
    component: #{name.inspect}
END

        msg << "    for:\n" 
        x.each do | data |
          msg << "    - #{data[:dependent].inspect}\n"
        end

        msg << <<"END"
    available:
    #{
    available_components.
    select(:name => name).to_a.
    map{|c| "- #{c.to_s.inspect}"}.
    join("\n    ")}
    selected:
      #{
    selected_components.
    selections[name].map do | q |
#$stderr.puts "name = #{name.inspect}"
#$stderr.puts "x = #{x.inspect}"
#$stderr.puts "q = #{q.inspect}"
q = q.to_hash unless Hash === q
      "constraint: %s\n      %s" % [ (q[:version] || '<<ANY>>').to_s.inspect, "by: #{q[:_by].to_s.inspect}" ]
    end.
    join("\n      ")}
---
END
      end
#    rescue Exception => err
#      $stderr.puts msg
#    ensure
      $stderr.puts msg
      raise Error, "UnresolvedComponent"
    end

    # Validates all components.
    # Check for unresolved components.
    # Then validate each component.
    def validate_components!
      notify_observers :before_validate_components!

      check_unresolved_components

      required_components.each do | c |
        c.validate!
      end

      notify_observers :after_validate_components!
      
      self
    end


    # Returns an Array of all required Components in
    # dependency order.
    def required_component_dependencies
      resolve_components!

      validate_components!

      component_dependencies required_components.to_a
    end


    # Returns an Array of all a Component's dependencies.
    # Forces resolution of components.
    def component_dependencies c
      resolve_components!

      validate_components!

      # If Array is given, dup it because we
      # are mutate it as a stack, otherwise create
      # new Array stack with c.
      stack = Array === c ? c.dup : [ c ]
      
      # Set of all dependencies of c.
      set = [ ]

      # Cache of dependencies of each Component.
      deps = { }

      until stack.empty?
        c = stack.pop
        next if c.nil?
        # puts "c = #{c}"
        unless set.include? c
          set << c
          d = (deps[c] ||= c.dependencies)
          stack.push(*d)
        end
      end

      # puts "set = #{set.inspect}"
      set = topographic_sort(set, :dependents => lambda { |c| deps[c] || EMPTY_ARRAY })
      # puts "set sort_topo = #{set.inspect}"


      set
    end


    ###########################################################
    # Facet Management.
    #

    # Returns a Hash of all facets collected and composed
    # from all required components.
    def facets 
      @facets ||=
        collected_facets[0]
    end

    # Returns a Hash of all non-composable facets for each
    # component.
    def comp_facets
      @comp_facets ||=
        collected_facets[1]
    end


    def collected_facets
#      @collected_facets ||=
        collect_facets
    end

    # Collects and composes all Facets provided in
    # all required components in dependencency order.
    #
    # Dependency order allows top-level components Facets to
    # occur before depended components in PATH, RUBYLIB, and
    # other search path oriented environment variables.
    def collect_facets coll = { }, comp_facet = { }
      component_dependencies(required_components.to_a).each do | c |
        next unless c.complete?
        # $stderr.puts "  collect_facets c = #{c}"
        c.provides.each do | facet |
          next unless facet.enabled?
          f = nil

          if facet.is_composable? 
            if f = coll[facet.key]
              f.compose_facet! facet
              f
            else
              f = coll[facet.key] = facet.dup
            end
          else
            (comp_facet[c] ||= [ ]) << facet
            f = facet
          end
        end
      end

      # Select all Path facets.
      # Append the current environment paths to the end.
      env_var_facets =
        Facet.
        prototypes.
        select { | f | f.is_env_var? }

      env_var_facets.
      map { | f | f.key }.
      each do | ft |
        fp = Facet.proto_by_key(ft)
        if (v = ENV[fp.env_var])
          f = coll[ft]
          facet = Facet.create(ft, 
                               :path => Cabar.path_split(v),
                               :context => self,
                               :owner => self)
          
          if f 
            f.compose_facet! facet  
          else
            coll[ft] = facet
          end
        end
      end

      # Select all Path facets.
      # Append the current environment paths to the end.
      env_var_facets.
      map { | f | f.key }.
      each do | ft |
        fp = Facet.proto_by_key(ft)
        if (v = ENV["CABAR_PRE_#{fp.env_var}"])
          f = coll[ft]

          facet = Facet.create(ft, 
                               :path => Cabar.path_split(v),
                               :context => self,
                               :owner => self)
          
          facet.compose_facet! f if f

          coll[ft] = facet
        end
      end

      [ coll, comp_facet ]
    end

    # Renders this context on a Cabar::Renderer,
    # after validating all components.
    def render r
      validate_components!
      r.render self
      r
    end

  end # class


end # module

