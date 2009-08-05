require 'cabar/base'

require 'cabar/resolver'
require 'cabar/main'


module Cabar

  # Plugin object for gracefully adding new functionality
  # to Cabar
  class Plugin < Base
    @@default_name = nil
    def self.default_name
      @@default_name
    end
    def self.default_name= x
      old = @@default_name
      @@default_name = x
      old
    end
    
    @@default_component = nil
    def self.default_component
      @@default_component
    end
    def self.default_component= x
      old = @@default_component
      @@default_component = x
      old
    end


    # The Plugin::Manager for this Plugin.
    attr_accessor :manager

    # Name of this Plugin.
    attr_accessor :name

    # If false, the Plugin is disabled by default.
    attr_accessor :enabled

    # Source of this Plugin.
    attr_accessor :file

    # Block to install the plugin components using the Builder.
    attr_accessor :block

    # Array of Facet objects defined by this Plugin.
    attr_accessor :facets
    
    # Array of Command objects defined by this Plugin.
    attr_accessor :commands

    # The Component that this Plugin is declared in.
    attr_accessor :component


    def initialize *args, &blk
      @file = caller[1]
      @facets = [ ]
      @commands = [ ]
      super

      @file = $1 if /^(.*):\d+/ === @file
      # $stderr.puts "Plugin file #{@file.inspect}"

      @name ||= @@default_name
      raise ArgumentError, "Component in #{@file} does not have a name" unless @name

      @component ||= @@default_component

      @block = blk

      # Get the main plugin manager now.
      @manager ||= Cabar::Main.current.plugin_manager

      # Register this plugin.
      register!
    end
    

    def _logger
      @manager._logger
    end


    # Installs the parts of the plugin.
    def register!
      # Register the plugin.
      @manager.register_plugin! self
    end


    # True if the plugin is enabled.
    def enabled?
      @enabled != false
    end


    # Installs the Plugin's parts.
    #
    # If the Plugin has not already been installed,
    # it's block is invoked by Plugin::Builder.
    #
    # This invokes Plugin#plugin_installed and Manager's :plugin_installed observers,
    # even if the the Plugin has already been installed.
    #
    # This allows multiple Main objects to exists while sharing the same Plugin::Manager.
    #
    # Called by Manager#register_plugin! the first time the Plugin is loaded and
    # and in load_plugin! every subsequent call to Manager#load_plugin!.
    #
    def install!
      error = nil
      return if @installed

      return if @installing
      @installing = true

      # $stderr.puts "  #{self} install! #{@file.inspect}"

      # Create a new builder, use the plugin's
      # block to execute the DSL.
      Builder.factory.new(:plugin => self, :default_doc => documentation, &@block)

      @installed = true

    rescue Exception => err
      error = err
      raise Error.new(:message => "In plugin #{name.inspect} (in #{file}): #{err.message}", :error => err)
      
    ensure
      @installing = false
      if @installed && ! error
        # $stderr.puts "  #{self} plugin_installed!"

        # Notify callback.
        self.plugin_installed!

        # Notify any active observers (i.e. Loader) so
        # it can associate existing plugins with the proper Components.
        # See comp.spec.
        @manager.notify_observers(:plugin_installed, self)
      end
    end


    # Callback from install!
    def plugin_installed!
      # $stderr.puts "#{self} plugin_installed! NOP"
    end


    def inspect
      "#<#{self.class} #{name.inspect} #{file.inspect}>"
    end


    def to_s
      "plugin #{name}"
    end

  end # class

end # module

