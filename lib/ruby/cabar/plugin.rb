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


    # Installs the plugin's parts.
    def install!
      return if @installed

      return if @installing
      @installing = true

      # Create a new builder, use the plugin's
      # block to execute the DSL.
      Builder.factory.new(:plugin => self, :default_doc => documentation, &@block)

      @installed = true
    ensure
      @installing = false
    end


    def inspect
      "#<#{self.class} #{name.inspect} #{file.inspect}>"
    end


    def to_s
      "plugin #{name}"
    end

  end # class

end # module

