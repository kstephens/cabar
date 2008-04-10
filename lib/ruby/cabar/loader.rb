require 'cabar/base'

require 'cabar/configuration'
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

    # The Cabar::Context to load Components into.
    attr_accessor :context

    attr_reader :component_search_path
    attr_reader :component_directories
  
    attr_reader :available_components

    def initialize opts = EMPTY_HASH
      @component_search_path = [ ]
      @component_search_path_pending = [ ]
      @component_directories = [ ]
      @component_directories_pending = [ ]
      @component_parse_pending = [ ]
     super
    end

    def _logger
      @_logger ||=
        Cabar::Logger.new(:name => :loader, 
                          :delegate => @context.main._logger)
    end

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
    # may add addition component search paths during
    # loading, to implement recursive component repositories.
    #
    def load_components!
      _logger.debug :"load_components!"

      notify_observers(:before_load_components!)

      path = nil
      dir = nil

      # While there are still component paths to search.
      @component_search_path_pending.cabar_each! do | path |
        _logger.debug do
          "search path #{path.inspect}"
        end
        @component_search_path << path
        
        search_for_component_directories(path).each do | dir |
          add_component_directory! dir
        end

        # While there are still components to load.
        @component_directories_pending.cabar_each! do | dir |
          @component_directories << dir
          _logger.debug do
            "component dir #{dir.inspect}"
          end

          parse_component! dir
        end

      end

      # Now that all components (and any plugins have been loaded),
      # the components can be fully configured.
      @component_parse_pending.cabar_each! do | c |
        c.parse_configuration!
        _logger.debug do
          "component #{c.inspect}"
        end
      end
      

      notify_observers(:after_load_components!)

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
      _logger.debug do
        "search_for_component_directories #{path.inspect}"
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
        "result #{x.inspect}"
      end

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
      notify_observers(:available_component_added!, c)
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
      
      _logger.info do
        "  loading #{conf_file.inspect}"
      end

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

          # Observe when plugins are installed.
          Cabar::Main.current.plugin_manager.add_observer(self, :plugin_installed, :plugin_installed!)

          plugin.each do | file |
            next unless file

            file = Cabar.path_expand(file, directory)

            _logger.debug do
              "    loading plugin #{file.inspect}"
            end

            require file

            _logger.debug do
              "    loading plugin #{file.inspect}: DONE"
            end
          end
        ensure
          Cabar::Plugin.default_name = save_name
          Cabar::Main.current.plugin_manager.delete_observer(self, :plugin_installed)
        end
      end

      _logger.info do
        "    loading #{conf_file.inspect}: DONE"
      end

      [ conf, comps, conf_file ]
    end

    # Observer callback for newly installed plugins.
    def plugin_installed! plugin_manager, plugin
      _logger.debug do
        "      plugin installed #{plugin.name.inspect} #{plugin.file.inspect}"
      end
      (@plugins ||= [ ]) << plugin
    end

    def parse_component! directory, conf_file = nil
      # The component.
      comp = nil

      # List of plugins loaded.
      @plugins = [ ]

      conf, comps, conf_file = parse_component_config directory, conf_file

      return nil unless conf

      _logger.info do
        "    loading #{conf_file}: DONE"
      end

      # Process each component definition.
      comps.each do | name, opts |
        # Overlay configuration.
        comp_config = (x = context.configuration.config['component']) && x['configure']
        comp_config ||= EMPTY_HASH
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
          _logger.debug do
            "      enabled #{conf_file.inspect}"
          end

          comp.parse_configuration_early!

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

