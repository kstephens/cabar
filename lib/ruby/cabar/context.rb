require 'cabar/base'

require 'cabar/component'
require 'cabar/facet'
require 'cabar/renderer'
require 'cabar/constraint'
require 'yaml'
require 'erb'


module Cabar
  class Context < Base
    attr_accessor :component_search_path
    attr_accessor :config_file_path

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
      self.component_search_path = ENV['CABAR_PATH'] || '.'
      self.config_file_path = ENV['CABAR_CONFIG'] || '~/.cabar.yml'
      super
    end

    # For Facet:: support.
    def base_directory
      @base_directory ||=
        directory
    end

    def config_file_path= x 
      case y = x
      when Array
      when String
        y = x.split(path_sep)
      else
        raise("YUCK")
      end

      @config_file_path = y.map { | p | File.expand_path(p) }.uniq_return!

      # Flush caches:
      @config = nil
      
      x
    end

    def config
      @config ||=
      begin
        cfg = nil

        config_file_path.
          reverse.
          select { | f | File.exists? f }.
          each do | f |
            y = _read_config_file f
            cfg ||= { }
            cfg.merge!(y)
          end
          
        cfg ||= {
          'cabar' => {
            'version' => true,
            'configuration' => {
            },
          },
        }

        unless Hash === cfg
          raise("configuration is not a Hash")
        end
        unless cfg = cfg['cabar']
          raise("configuration is not a Cabar configuration file")
        end
        unless cfg['version']
          raise("configuration does not have a version")
        end
        unless cfg = cfg['configuration']
          raise("configuration is not a Cabar configuration file")
        end

        cfg[:config_file_path] = config_file_path

        cfg
      end
    end

    def _read_config_file file
      File.open(file) do | fh |
        template = ERB.new fh.read
        fh = template.result binding
        YAML::load fh
      end
    rescue Exception => err
      raise("Problem reading config file #{file.inspect}: #{err.inspect}")
    end

    ###########################################################

    def component_search_path= x 
      case y = x
      when Array
      when String
        y = x.split(path_sep)
      else
        raise("YUCK")
      end

      @component_search_path = y.map { | p | File.expand_path(p) }.uniq_return!

      # Flush caches:
      @component_directories = nil
      @available_components = nil
      
      x
    end

    # Returns a list of all component directories.
    def component_directories
      @component_directories ||=
      begin
        # Find all */*/cabar.yml or */cabar.yml files.
        x = component_search_path.map do | p |
          [ "#{p}/*/*/cabar.yml", "#{p}/*/cabar.yml" ]
        end.flatten_return!
        
        # Glob matching.
        x.map! do | f |
          Dir[f]
        end.flatten_return!

        # Take the directories.
        x.map! do | f |
          File.dirname(f)
        end

        # Unique.
        x.uniq_return!
      end
    end

    # Helper method to create a Component.
    def create_component(opts)
      c = Facet.create :component, opts
      c.context = self
      c
    end

    ##################################################################

    # Read all component directories configuration files. 
    def read_components
      component_directories.each do | dir |
        parse_configuration(dir, nil, @available_components)
      end
    end

    #
    # Returns a set of all availabe components
    # found through the component_directories search path.
    #
    def available_components
      unless @available_components
        @available_components = Cabar::Version::Set.new

        # Read components.
        # This will also load any plugins.
        read_components

        # Now they can be parse since all the plugins have been loaded.
        @available_components.each do | c |
          c.parse_configuration!
        end
      end

      @available_components
    end

    # Called when a component has been added.
    def add_available_component! c, a = @avaliable_components
      a << c
      c
    end


    # Returns the selected components.
    def selected_components
      @selected_components ||=
      begin
        @selected_components = Cabar::Component::Set.new available_components.dup
        
        _do_configuration

        @selected_components
      end
    end

    def _do_configuration
      by = "config@#{config[:config_file_path].inspect}"
      
      cfg = config
      cfg &&= cfg['select']
      cfg &&= cfg['component']
      cfg ||= EMPTY_HASH
      
      # Apply configuration to components.
      cfg.each do | name, opts |
        opts = _normalize_config_opts opts
        opts[:name] = name unless name.nil?
        opts[:_by] = by
        
        select_component opts
      end

      cfg = config
      cfg &&= cfg['require']
      cfg &&= cfg['component']
      cfg ||= EMPTY_HASH
      
      # Apply configuration to components.
      cfg.each do | name, opts |
        opts = _normalize_config_opts opts
        opts[:name] = name unless name.nil?
        opts[:_by] = by
        
        require_component opts
      end

      # Do plugin configurations.
      # plugin.each do | plugin |
      #  plugin.apply_context_configuration self
      # end
    end

    def _normalize_config_opts opts
      opts = opts.inject({ }) do | h, kv |
        k, v = *kv
        h[k.to_sym] = v
        h
      end
      case opts
      when nil, false
        opts = { :enabled => false }
      when true
        opts = { }
      when String, Float, Integer
        opts = { :version => opts }
      end
      
      opts[:version] = Cabar::Version::Requirement.create_cabar(opts[:version]) if opts[:version]
      
      opts
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
      c = _require_component opts, &blk
      add_top_level_component! c
      c
    end

    # Requires a specific component and/or version.
    def _require_component opts, &blk
      r = resolve_component opts, :all, &blk
      case r.size
      when 0
        raise("Cannot find required component #{opts.inspect}")
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
      raise("UnresolvedComponent")
    end

    # Validates all components.
    def validate_components!
      check_unresolved_components

      required_components.each do | c |
        c.validate!
      end
      
      self
    end

    # FIXME
    def path_sep
      ':'
    end

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
                               :path => v.split(path_sep), 
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
                               :path => v.split(path_sep), 
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

private

    def valid_string? str
      String === str && ! str.empty?
    end

    def parse_configuration(directory, conf_file = nil, comps_loaded = nil) 
      comps_loaded ||=
        [ ]

      conf_file ||= 
        File.join(directory, "cabar.yml")

      begin
        conf = _read_config_file conf_file
        
        # Basic component configuration file.
        (Hash === conf) || raise("#{conf_file} not a Cabar component file")
        conf = conf['cabar'] || raise("#{conf_file} not a Cabar component file")
        conf['version'] || raise("#{conf_file} does not have a Cabar version")

        # Handle plugins.
        if plugin = conf['plugin']
          plugin = [ plugin ] unless Array === plugin
          plugin.each do | file |
            file = File.expand_path(file, directory) 
            # $stderr.puts "#{$0}: using plugin #{plugin}"
            require file
          end
        end

        # Handle components.
        comps = conf['component'] || raise("does not have a component definition")

        if comps.size >= 2 && comps['name'] && comps['version']
          name = comps['name']
          comps.delete 'name'
          comps = { name => comps }
        end

        comps.each do | name, opts |
          # Overlay configuration.
          comp_config = config['configure'] || EMPTY_HASH
          comp_config = comp_config[name] || EMPTY_HASH
          opts.merge! comp_config

          opts[:name] = name
          opts[:directory] = directory
          opts[:context] = self
          opts[:_config_file] = conf_file

          comp = create_component opts

          unless valid_string? comp.name
            raise "component in #{directory.inspect} has no name" 
          end
          unless Version === comp.version
            raise "component #{name.inspect} has no version #{comp.version.inspect}"
          end

          # Save config hash for later.
          comp._config = conf

          # Register component, if it's enabled.
          if comp.enabled?
            add_available_component! comp, comps_loaded
          end
        end

      rescue Exception => err
        raise "in #{conf_file}:\n  in #{self.inspect}:\n  #{err}\n  #{err.backtrace.join("\n  ")}"
      
      end


      comps_loaded
    end
    
  end # class


end # module

