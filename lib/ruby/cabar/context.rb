require 'cabar/base'

require 'cabar/configuration'
require 'cabar/loader'
require 'cabar/component'
require 'cabar/facet'
require 'cabar/renderer'
require 'cabar/constraint'


module Cabar
  class Context < Base
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

    def configuration
      @configuration ||= Cabar::Configuration.new(:context => self)
    end

    def config
      configuration.config
    end

    def config_raw
      configuration.config_raw
    end

    def apply_configuration!
      configuration.apply_configuration! self
    end

    ##################################################################
    # Loading 
    #

    # Returns the loader.
    def loader
      @loader ||= Cabar::Loader.new(:context => self)
    end

    #
    # Returns a set of all availabe components
    # found through the component_directories search path.
    #
    def available_components
      loader.available_components
    end

    # Returns the selected components.
    def selected_components
      @selected_components ||=
      begin
        @selected_components = Cabar::Component::Set.new available_components.dup
        
        apply_configuration!

        @selected_components
      end
    end

    # Selects a specific matching component.
    def select_component opts, &blk
      s = selected_components.select! opts, &blk
      s
    end

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
      c = _require_component opts, &blk
      add_top_level_component! c
      c
    end

    # Requires a specific component and/or version.
    def _require_component opts, &blk
      r = resolve_component opts, :all, &blk
      case r.size
      when 0
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
      end
      c
    end

    # Called when a component is required.
    def add_required_component! c
      @required_components << c
      c
    end

    # Called to resolve all component dependencies:
    # Pass 1: select all components dependencies.
    # Pass 2: resolve all explicit dependencies after selection has been reduced.
    # Pass 3: require the latest dependencies for non-ambigious selections.
    def resolve_components!
      required_components.each do | c |
        c.select_component!
      end

      required_components.each do | c |
        c.resolve_component!
      end

      required_components.each do | c |
        c.require_component!
      end

      self
    end
    
    # Returns true if component was required.
    def required_component? c
      required_components.include? c
    end

    # Called during resolve_compoent!
    def unresolved_component! opts
      (@unresolved_components[opts[:name]] ||= [ ]) << opts
      self
    end

    def unresolved_components? 
      ! unresolved_components.empty?
    end

    def check_unresolved_components
      return self unless unresolved_components? 

      msg = ''

      unresolved_components.each do | name, x |
        msg << <<"END"
Connot resolve component #{name.inspect}:
  Available:
    #{
    available_components.
    select(:name => name).to_a.
    map{|c| c.to_s}.
    join("\n    ")}
  Requested:
    #{
    selected_components.
    selections[name].map do | q |
      "%s\n      %s" % [ (q[:version] || '<<ANY>>'), "by #{q[:_by]}" ]
    end.
    join("\n    ")}
END
        x.each do | data |
          msg << <<"END"
  For #{data[:dependent]}
END
        end
      end
      $stderr.puts msg
      raise Error, "UnresolvedComponent"
    end

    # Validates all components.
    def validate_components!
      check_unresolved_components

      required_components.each do | c |
        c.validate!
      end
      
      self
    end


    ###########################################################
    # Facet Management.
    #

    # Returns a list of call facets collected from
    # all required components.
    def facets 
      @facets ||=
        collect_facets.first
    end

    def comp_facets
      @comp_facets ||=
        collect_facets.pop
    end

    def collect_facets coll = { }, comp_facet = { }
      required_components.each do | c |
        c.provides.each do | facet |
          if facet.is_composable? 
            if f = coll[facet.key.to_s]
              f.compose_facet! facet
            else
              coll[facet.key.to_s] = facet.dup
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
                               :path => v.split(Cabar.path_sep), 
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
        if (v = ENV["PRE_#{fp.var}"])
          f = coll[ft]

          facet = Facet.create(ft, 
                               :path => v.split(Cabar.path_sep), 
                               :owner => self)
          
          facet.compose_facet! f if f

          coll[ft] = facet
        end
      end

      [ coll, comp_facet ]
    end

    def render r
      validate_components!
      r.render self
      r
    end

  end # class


end # module

