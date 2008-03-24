require 'cabar/base'

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
    attr_reader :main

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
      @configuration ||= Cabar::Configuration.new(:context => self)
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
      if (x = ENV['CABAR_TOP_LEVEL']) && ! x.empty?
        x = x.split(/\s+|\s*,\s*/)
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
    # Returns a set of all availabe components
    # found through the component directories search path.
    #
    def available_components
      loader.available_components
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
    def select_component opts, &blk
      notify_observers :before_select_component, opts

      s = selected_components.select! opts, &blk

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
    def resolve_component opts, all = false, &blk
      # puts "resolve #{opts.inspect}, #{all.inspect}"
      c = selected_components.select opts, &blk
      # puts "  c = #{c.size} #{c.inspect}"
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
    def require_component opts, &blk
      return nil unless opts

      notify_observers :before_require_component, opts

      c = _require_component opts, &blk
      add_top_level_component! c

      notify_observers :after_require_component, opts, c

      c
    end

    # Requires a specific component and/or version.
    # Use internally by cabar during dependency
    # resolution.
    # Does not add component to top_level_components list.
    def _require_component opts, &blk
      r = resolve_component opts, :all, &blk
      case r.size
      when 0
        constraint = opts
        opts = opts.to_hash unless Hash === opts
        opts[:dependent] = constraint.to_s
        unresolved_component! opts
        check_unresolved_components
        raise Error, "Cannot find required component #{opts.inspect}"
      else
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
        collect_facets.first
    end

    # Returns a Hash of all non-composable facets for each
    # component.
    def comp_facets
      @comp_facets ||=
        collect_facets.pop
    end

    # Collects and composes all Facets provided in
    # all required components.
    def collect_facets coll = { }, comp_facet = { }
      # Collect/compose all facets in dependency order.
      @required_components.each do | c |
        next unless c.complete?
        c.provides.each do | facet |
          next unless facet.enabled?
          if facet.is_composable? 
            if f = coll[facet.key]
              f.compose_facet! facet
            else
              coll[facet.key] = facet.dup
            end
          else
            (comp_facet[c] ||= [ ]) << facet
          end
        end
      end

      # Select all EnvVarPath facets.
      # Append the current environment paths to the end.
      Facet.
      prototypes.
      select { | f | f.is_env_var? }.
      map { | f | f.key }.
      each do | ft |
        fp = Facet.proto_by_key(ft)
        if (v = ENV[fp.var])
          f = coll[ft]
          facet = Facet.create(ft, 
                               :path => Cabar.path_split(v),
                               :owner => self)
          
          if f 
            f.compose_facet! facet  
          else
            coll[ft] = facet
          end
        end
      end

      # Select all EnvVarPath facets.
      # Append the current environment paths to the end.
      Facet.
      prototypes.
      select { | f | f.is_env_var? }.
      map { | f | f.key }.
      each do | ft |
        fp = Facet.proto_by_key(ft)
        if (v = ENV["CABAR_PRE_#{fp.var}"])
          f = coll[ft]

          facet = Facet.create(ft, 
                               :path => Cabar.path_split(v), 
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

