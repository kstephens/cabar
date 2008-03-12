require 'cabar/base'

require 'cabar/configuration'
require 'cabar/component'


module Cabar
  class Loader < Base
    attr_accessor :context

    attr_accessor :verbose

    attr_reader :component_search_path
    attr_reader :component_directories
  
    attr_reader :available_components

    def initialize opts = EMPTY_HASH
      @component_search_path = [ ]
      @component_search_path_pending = [ ]
      @component_directories = [ ]
      @component_directories_pending = [ ]
      @component_parse_pending = [ ]
      @verbose = ENV['CABAR_DEBUG'] ? true : false
     super
    end

    def log msg, force = nil
      $stderr.puts msg if force || @verbose
    end

    def add_component_search_path! path
      if Array === path
        path.each { | x | add_component_search_path! x }
        return self
      end
      path = Cabar.path_expand(path)
      return self if @component_search_path.include? path
      return self if @component_search_path_pending.include? path
      @component_search_path_pending << path
      log "  add_component_search_path! #{path.inspect}"
      self
    end

    def add_component_directory! path
      path = Cabar.path_expand(path)
      return self if @component_directories.include? path
      return self if @component_directories_pending.include? path
      @component_directories_pending << path
      self
    end

    def load_components!
      log "load_components!"

      path = nil
      dir = nil

      # While there are still component paths to search.
      @component_search_path_pending.cabar_each! do | path |
        log "search path #{path.inspect}"
        @component_search_path << path
        
        search_for_component_directories(path).each do | dir |
          add_component_directory! dir
        end

        # While there are still components to load.
        @component_directories_pending.cabar_each! do | dir |
          @component_directories << dir
          log "  component dir #{dir.inspect}"
          
          parse_component! dir
        end

      end

      # Now that all components (and any plugins have been loaded),
      # the components can be fully configured.
      @component_parse_pending.cabar_each! do | c |
        c.parse_configuration!
        log "component #{c.inspect}"
      end
      
      self
    rescue Exception => err
      raise Error.new('Loading components', 
                      :error => err, 
                      :directory => dir, 
                      :pending_paths => @component_search_path_pending,
                      :pending_directories => @component_directories_pending)
    end

    # Returns a list of all component directories.
    def search_for_component_directories *path
      log "search_for_component_directories #{path.inspect}"

      # Find all */*/cabar.yml or */cabar.yml files.
      x = path.map do | p |
        # Handle '@foo/bar' as a direct reference to component foo/bar.
        p = p.dup
        if p.sub!(/^@/, '' )
          [ "#{p}/cabar.yml" ]
        else
          [ "#{p}/*/*/cabar.yml", "#{p}/*/cabar.yml" ]
        end
      end.cabar_flatten_return!
      
      # Glob matching.
      x.map! do | f |
        Dir[f]
      end.cabar_flatten_return!
      
      # Take the directories.
      x.map! do | f |
        File.dirname(f)
      end
      
      # Unique.
      x = x.cabar_uniq_return!

      log "result #{x.inspect}"

      x
    end


    ##################################################################

    #
    # Returns a set of all availabe components
    # found through the component_directories search path.
    #
    def available_components
      unless @available_components
        @available_components = Cabar::Version::Set.new
        load_components!
      end

      @available_components
    end


    # Called when a component has been added.
    def add_available_component! c
      @available_components << c
      @component_parse_pending << c
    end


    # Helper method to create a Component.
    def create_component opts
      c = Component.factory.new opts
      c.context = @context
      c
    end

private

    def parse_component_config directory, conf_file = nil
      conf_file ||= 
        File.join(directory, "cabar.yml")
      
      log "    loading #{conf_file}"

      conf = @context.configuration.read_config_file conf_file
      conf = conf['cabar']
      
      # Enabled?
      if conf['enabled'] != nil && ! conf['enabled']
        return nil
      end

      # Handle components.
      unless comps = conf['component']
        raise Error, "does not have a component definition"
      end
      unless Hash === comps
        comps = { }
      end

      # Infer component name/version from directory.
      infer_component_name comps, directory

      # Transform:
      #
      #   component:
      #     name: NAME
      #     version: VERSION
      #     ...
      # TO:
      #
      #   component:
      #     NAME:
      #       version: VERSION
      #       ...
      #
      name = nil
      if comps.size >= 2 && comps['name'] && comps['version']
        name = comps['name']
        comps.delete 'name'
        comps = { name => comps }
      end
      
      # Handle plugins.
      # Use component name as the default name.
      if plugin = conf['plugin']
        begin
          plugin = [ plugin ] unless Array === plugin

          save_name = Cabar::Plugin.default_name = name

          Cabar::Main.current.plugin_manager.add_observer(self, :plugin_installed, :plugin_installed!)

          plugin.each do | file |
            file = Cabar.path_expand(file, directory) 
            log "    loading plugin #{file}"
            require file
            log "    loading plugin #{file}: DONE"
          end
        ensure
          Cabar::Plugin.default_name = save_name
          Cabar::Main.current.plugin_manager.delete_observer(self, :plugin_installed)
        end
      end

      log "    loading #{conf_file}: DONE"

      [ conf, comps, conf_file ]
    end

    def plugin_installed! plugin
      log "      plugin installed #{plugin.name.inspect} #{plugin.file.inspect}"
      (@plugins ||= [ ]) << plugin
    end

    def parse_component! directory, conf_file = nil
      # List of plugins loaded.
      @plugins = [ ]

      conf, comps, conf_file = parse_component_config directory, conf_file

      return nil unless conf

      log "    loading #{conf_file}: DONE"

      # Process each component definition.
      comps.each do | name, opts |
        # Overlay configuration.
        comp_config = @context.config['configure'] || EMPTY_HASH
        comp_config = comp_config[name] || EMPTY_HASH
        opts.cabar_merge! comp_config
        
        opts[:name] = name
        opts[:directory] = directory
        opts[:context] = self
        opts[:enabled] = conf['enabled']
        opts[:_config_file] = conf_file
        opts[:plugins] = @plugins

        comp = create_component opts
        
        unless valid_string? comp.name
          raise Error, "component in #{directory.inspect} has no name" 
        end
        unless Version === comp.version
          raise Error, "component #{name.inspect} has no version #{comp.version.inspect}"
        end
        
        # Save config hash for later.
        comp._config = conf

        # Register component, if it's enabled.
        if comp.enabled?
          log "      enabled #{conf_file}"
          comp.parse_configuration_early!

          add_available_component! comp
        end

        log "    parse #{conf_file}: DONE"

        comp
      end
    rescue Exception => err
      raise Error.new("in #{conf_file.inspect}: in #{self.class}", :error => err)
    end
    
    def infer_component_name comps, directory
      # Infer component name/version from directory name.
      unless comps['name'] && comps['version']
        case directory
          # name/version
        when /\/([a-z_][^\/]*)[\/-]([0-9]+(\.[0-9])*)$/i
          comps['name'] ||= $1
          comps['version'] ||= $2
          # name
        when /\/([a-z_][^\/]*)$/i
          comps['name'] ||= $1
          comps['version'] ||= '0.1'
        else
          raise Error, "Cannot infer component name/version from directory"
        end
      end

    end


    def valid_string? str
      String === str && ! str.empty?
    end

    
  end # class

end # module

