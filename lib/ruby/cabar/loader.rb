require 'cabar/base'

require 'cabar/component'
require 'cabar/observer'


module Cabar
  # Loads components based on component search path (CABAR_PATH).
  # 
  # TO DO:
  #
  # * Refactor to handle gems and debian packages.
  #
  class Loader < Base
    include Cabar::Observer::Observed

    # The Cabar::Main object.
    attr_accessor :main

    # The Cabar::Configuration object.
    attr_accessor :configuration

    # The Cabar::Resolver to load Components into.
    # attr_accessor :resolver

    # The directories to search for Components.
    attr_reader :component_search_path

    # The component directories parsed.
    attr_reader :component_directories
  
    # Cabar::Version::Set of available Components.
    attr_reader :available_components


    def initialize opts = EMPTY_HASH
      @component_search_path = [ ]
      @component_search_path_pending = [ ]
      @component_directories = [ ]
      @component_directories_pending = [ ]
      @component_configure_pending = [ ]
      super

      raise TypeError, "main is not defined" unless Main === main
    end


    def _logger
      @_logger ||=
        Cabar::Logger.new(:name => :loader, 
                          :delegate => (main || Main.current)._logger)
    end


    # Returns self.
    def add_component_search_path! path, opts = nil
      opts ||= EMPTY_HASH

      if Array === path
        path.each { | x | add_component_search_path! x }
        return self
      end
      path = Cabar.path_expand(path)

      unless opts[:force]
        return self if @component_search_path.include? path
        return self if @component_search_path_pending.include? path
      else
        @component_search_path_pending.delete path
      end

      case opts[:priority] || :after
      when :before
        @component_search_path_pending.unshift path
      when :after
        @component_search_path_pending << path
      else
        raise ArgumentError, "position must be :before or :after"
      end

      _logger.debug do
        "add_component_search_path! #{path.inspect} #{opts.inspect}"
      end

      self
    end


    def add_component_directory! path
      path = Cabar.path_expand(path)
      return self if @component_directories.include? path
      return self if @component_directories_pending.include? path
      @component_directories_pending << path
      self
    end


    # Force loading of a component directory.
    def load_component! directory, opts = nil
      add_component_search_path!("@#{directory}", opts)
    end


    # Load components from the component_search_path
    # and component_directory queues.
    #
    # A queue is used because some components
    # may add component search paths during
    # loading, to implement recursive component repositories.
    #
    # cabar/plugin/core.rb is loaded here to support the "components" Facet for comp/ directories.
    def load_components!
      _logger.debug :"load_components!"

      plugin_manager.load_plugin! "#{Cabar.cabar_base_directory}/lib/ruby/cabar/plugin/core.rb"

      notify_observers(:before_load_components!)

      _scan_pending_directories!

      # Load each most recent component's plugins.
      load_most_recent_plugins!

      # Now that all components (and any plugins have been loaded),
      # the components can be fully configured.
      @component_configure_pending.cabar_each! do | c |
        c.configure!
        _logger.debug do
          "configure component #{c.inspect}"
        end
      end

      notify_observers(:after_load_components!)

      self
    end


    def _scan_pending_directories!
      path = nil
      dir = nil

      _logger.debug do 
        "_scan_pending_directories!"
      end

      # While there are still component paths to search,
      @component_search_path_pending.cabar_each! do | path |
        _logger.debug do
          "  search path #{path.inspect}"
        end
        @component_search_path << path
        
        search_for_component_directories!(path).each do | dir |
          add_component_directory! dir
        end

        # While there are still components to load,
        @component_directories_pending.cabar_each! do | dir |
          @component_directories << dir
          _logger.debug do
            "  component dir #{dir.inspect}"
          end

          # Create each component.
          _load_component! dir
        end
      end

      _logger.debug do 
        "_scan_pending_directories!: DONE"
      end

    rescue Exception => err
      raise Error.new('Loading components', 
                      :error => err, 
                      :directory => dir, 
                      :pending_paths => @component_search_path_pending,
                      :pending_directories => @component_directories_pending)

    end


    # Returns a list of all component directories.
    def search_for_component_directories! *path
      _logger.debug do
        "search_for_component_directories! #{path.inspect}"
      end

      # Find all */*/cabar.yml or */cabar.yml files.
      x = path.map do | p |
        # Handle '@foo/bar' as a direct reference to component foo/bar.
        p = p.dup
        if p.sub!(/^@/, '' )
          [ "#{p}/cabar.yml" ]
        else
          [ "#{p}/*/[01234567889]*/cabar.yml", "#{p}/*/std/cabar.yml", "#{p}/*/cabar.yml" ]
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

      _logger.debug do
        "search_for_component_directories! #{path.inspect} => #{x.inspect}"
      end

      x
    end


    ##################################################################

    #
    # Returns a set of all available Components
    # found through the component_directories search path.
    #
    # The most recent component's plugins are loaded.
    def available_components
      unless @available_components
        @available_components = Cabar::Version::Set.new

        load_components!
      end

      @available_components
    end


    # Called when a component has been added.
    def add_available_component! c
      unless @available_components.include?(c)
        @available_components << c
        @component_configure_pending << c
        notify_observers(:available_component_added!, c)
      end
    end


    def inspect
      "#<#{self.class}:#{'0x%0x' % self.object_id}>"
    end
    

private

    # Helper method to create a Component.
    def create_component opts
      opts[:_loader] = self
      c = Component.factory.new opts
      c
    end


    def _parse_component_config directory, conf_file = nil
      raise TypeError, "main is not defined" unless Main === main

      conf_file ||= 
        File.join(directory, "cabar.yml")
      
      _logger.info do
        "  loading #{conf_file.inspect}"
      end

      conf = configuration.read_config_file conf_file
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
      
      _logger.info do
        "    loading #{conf_file.inspect}: DONE"
      end

      [ conf, comps, conf_file ]
    end


    # Returns the cabar Component with the greatest version.
    def cabar_component
      @cabar_component ||=
        available_components['cabar'].first || 
        (raise Error, "Cannot find cabar component.")
    end


    # Loads the plugins from the most recent version of each component.
    def load_most_recent_plugins!
      _logger.info do
        "loading plugins"
      end

      notify_observers(:before_load_plugins!)

      plugin_manager.load_plugin! "#{Cabar.cabar_base_directory}/lib/ruby/cabar/plugin/cabar.rb"

      available_components.most_recent.each do | comp |
        load_plugin_for_component! comp
      end

      # Associate all core or orphaned Plugins with Cabar itself.
      associate_orphaned_plugins! cabar_component

      notify_observers(:after_load_plugins!)

      _logger.info do
        "loading plugins: DONE"
      end

      self
    end


   def load_plugin_for_component! comp
      return if comp.plugins_status

      notify_observers(:before_load_plugin_for_component!, comp)

      default_component_save = Cabar::Plugin.default_component
      Cabar::Plugin.default_component = comp

      @component = comp
      @plugins = [ ]
      comp.plugins_status = :loading

      load_plugins! comp._config['plugin'], comp.name, comp.directory

      comp.plugins = @plugins
      comp.plugins_status = :loaded
      
      notify_observers(:after_load_plugin_for_component!, comp)
    ensure
      @component = @plugins = nil
      Cabar::Plugin.default_component = default_component_save
    end


    # Loads a component's plugins.
    # Use component name as the default Plugin name.
    def load_plugins! plugin, name, directory
      return unless plugin

      plugin = [ plugin ] unless Array === plugin
      
      default_name_save = Cabar::Plugin.default_name = name
     
      # Observe when plugins are installed.
      plugin_manager.add_observer(self, :plugin_installed, :plugin_installed!)
      
      plugin.each do | file |
        next unless file
        
        file = Cabar.path_expand(file, directory)
        
        plugin_manager.load_plugin! file
      end
    ensure
      Cabar::Plugin.default_name = default_name_save

      plugin_manager.delete_observer(self, :plugin_installed)
    end


    def plugin_manager
      main.plugin_manager
    end


    # Observer callback for associating Plugins with Components.
    def plugin_installed! plugin_manager, plugin
      _logger.debug do
        "      plugin installed #{plugin.name.inspect} #{plugin.file.inspect}"
      end
      @plugins << plugin
    end


    def associate_orphaned_plugins! comp
      raise TypeError, "expected Component, given #{comp.class}" unless Component === comp
      plugin_manager.plugins.each do | p |
        p.component ||= comp
      end
    end


    def _load_component! directory, conf_file = nil
      # The component.
      comp = nil

      conf, comps, conf_file = _parse_component_config directory, conf_file

      return nil unless conf

      _logger.info do
        "    loading #{conf_file}: DONE"
      end

      # Process each component definition.
      comps.each do | name, opts |
        # Overlay configuration.
        comp_config = 
          (x = configuration.config['component']) && 
          x['configure']
        comp_config ||= EMPTY_HASH
        comp_config = comp_config[name] || EMPTY_HASH
        # $stderr.puts "comp_config #{name.inspect} => #{comp_config.inspect}"
        opts.cabar_merge! comp_config
        # puts "comp opts #{name.inspect} => "; pp opts
        
        opts['name'] ||= name
        opts['directory'] ||= directory
        # opts['enabled'] = conf['enabled']
        opts[:_config_file] = conf_file
        # puts "comp opts #{name.inspect} => "; pp opts
        opts[:_loader] = self
        # opts[:resolver] = self # HUH: is this right?

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
        # Do early configuration (i.e.:  handle "components" Facet comp/ directories).
        if comp.enabled?
          _logger.debug do
            "      enabled #{conf_file.inspect}"
          end

          comp.configure_early!

          add_available_component! comp
        else
          _logger.info do 
            "      component #{comp} disabled"
          end
        end

        _logger.info do
          "    parse #{conf_file.inspect}: DONE"
        end

        comp
      end
    rescue Exception => err
      if comp
        comp._options[:enabled] = false
      end
      raise Error.new("in #{conf_file.inspect}: in #{self.class}", :error => err)
    end
    

    # Attempt to infer a component's name or version 
    # if not specified by the component's cabar.yml.
    # Plugins can register for :infer_component_name action via
    # add_observer.
    def infer_component_name comps, directory
      # Give plugins a chance.
      notify_observers(:infer_component_name, comps, directory)

      # Infer component name/version from directory name.
      unless comps['name'] && comps['version']
        case directory
          # name/version OR name-version
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

