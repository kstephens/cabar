require 'cabar/plugin'

require 'cabar/base'
require 'cabar/observer'
require 'cabar/plugin/builder'


module Cabar

  class Plugin

    # Manages plugins.
    class Manager < Base
      include Cabar::Observer::Observed

      # The Cabar::Main object.
      attr_accessor :main

      # The Array of Plugin objects in installed order.
      attr_reader :plugins

      # Hash of Plugin objects by name.
      attr_reader :plugin_by_name

      # Hash of Array of Plugin objects by absolute file name.
      attr_reader :plugin_by_file


      def initialize *args
        @plugins = [ ]
        @plugin_by_name = { }
        @plugin_by_file = { }
        super
      end


      def _logger
        @_logger ||
          @main._logger
      end


      def load_plugin! file
        file += ".rb" unless /\.rb$/ === file
        file = File.expand_path(file)

        if plugins = @plugin_by_file[file]
          # Notify any active observers (i.e. Loader) so
          # it can associate existing plugins with the proper Components.
          # See comp.spec.
          plugins.each do | plugin |
            notify_observers(:plugin_installed, plugin)
          end

          :already
        else
          @plugin_by_file[file] = [ ]
          _logger.info { "plugin: loading plugin #{file.inspect}" }
          require file
          _logger.info { "plugin: loading plugin #{file.inspect}: DONE" }

          self
        end
      end


      def register_plugin! plugin
        unless @plugin_by_file[plugin.file]
          raise Error, "Plugin not loaded via Plugin::Manager#load_plugin!"
        end

        # Overlay configuration options.
        config_opts = main.configuration.config['plugin']
        config_opts &&= config_opts[plugin.name]

        _logger.debug { "plugin: #{plugin} configuration #{config_opts.inspect}" }

        if config_opts
          opts = plugin._options.dup
          opts.cabar_merge!(config_opts)
          plugin._options = opts
          _logger.info { "plugin: #{plugin} configuration #{opts.inspect}" }
        end

        # Do not register if disabled.
        unless plugin.enabled?
          _logger.debug { "plugin: #{plugin} named #{name} disabled" }
          return
        end

        name = plugin.name.to_s

        # Unfortunately we need to allow multiple plugins to be
        # loaded but not registered.
        if @plugin_by_name[name]
          _logger.debug { "plugin: #{plugin} named #{name} already exists" }
          return
        end

        # This realizes the plugin.
        plugin.install!

        plugin.manager = self
        @plugins << plugin
        @plugin_by_name[name] = plugin
        @plugin_by_file[plugin.file] << plugin

        notify_observers(:plugin_installed, plugin)
        
        _logger.info { "plugin: #{plugin} installed #{opts.inspect}" }

        self
      end
    end

  end # class

end # module

