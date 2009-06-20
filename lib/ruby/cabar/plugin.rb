require 'cabar/base'

require 'cabar/resolver'
require 'cabar/command/helper' # Standard command support.
require 'cabar/facet/standard' # Cabar::Facet::Path
require 'cabar/main'
require 'cabar/observer'


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


    # The manager for this plugin.
    attr_accessor :manager

    # Name of this plugin.
    attr_accessor :name

    # If false, the plugin is disabled by default.
    attr_accessor :enabled

    # Source of this plugin.
    attr_accessor :file

    # Block to install the plugin components using the Builder.
    attr_accessor :block

    # Array of Facets defined by this plugin.
    attr_accessor :facets
    
    # Array of commands defined by this plugin.
    attr_accessor :commands

    # The Component that this plugin belongs to.
    attr_accessor :component


    def initialize *args, &blk
      @file = caller[1]
      @facets = [ ]
      @commands = [ ]
      super

      @file = $1 if /^(.*):\d+:in / === @file
      @name ||= @@default_name
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


    # Manages plugins.
    class Manager < Base
      include Cabar::Observer::Observed

      # The Cabar::Main object.
      attr_accessor :main

      # The list of plugins in installed order.
      attr_reader :plugins

      # Plugin by name.
      attr_reader :plugin_by_name


      def initialize *args
        @plugins = [ ]
        @plugin_by_name = { }
        super
      end


      def _logger
        @_logger ||
          @main._logger
      end


      def register_plugin! plugin
        # Overlay configuration options.
        config_opts = main.resolver.configuration.config['plugin']
        config_opts &&= config_opts[plugin.name]

        _logger.debug { "plugin: #{plugin} configuration #{config_opts.inspect}" }

        if config_opts
          opts = plugin._options.dup
          opts.cabar_merge!(config_opts)
          plugin._options = opts
          _logger.info { "plugin: #{plugin} configuration #{opts.inspect}" }
        end

        # Do not register if disabled.
        return unless plugin.enabled?

        name = plugin.name.to_s

        # Unfortunately we need to allow multiple plugins to be
        # loaded but not registered.
        if @plugin_by_name[name]
          return
        end

        # This realizes the plugin.
        plugin.install!

        plugin.manager = self
        @plugins << plugin
        @plugin_by_name[name] = plugin

        notify_observers(:plugin_installed, plugin)
        
        self
      end
    end


    # Builder for plugin artifacts.
    #
    # Provides basic DSL for constructing new Plugin elements:
    #
    # * Commands
    # * Command Groups
    # * Facets
    class Builder < Base
      # The plugin being built.
      attr_accessor :plugin
      
      # The default documentation.
      attr_accessor :default_doc

      def initialize *args, &blk
        @target = nil
        @target_stack = [ ]
        @doc = nil
        @doc_default = nil
        super
        instance_eval &blk if block_given?
      end


      def _logger
        @_logger ||=
          @plugin._logger
      end


      # Define :documentation for the next item.
      def doc text
        text << "\n" unless /\n\Z/ =~ text
        if @doc
          $stderr.puts "cabar: warning doc already defined as #{@doc.inspect} at #{caller[0]}"
        end
        @doc = text.dup.freeze
      end


      # Define a Facet.
      def facet name, opts = nil, &blk
        opts = _take_doc(opts)
        opts[:key] = name
        opts[:class] ||= Facet::Path
        cls = opts[:class]
        opts.delete(:class)
        opts[:_defined_in] = @plugin

        # Create a new Facet prototype.
        facet = cls.new(opts)

        # Initialize it.
        if block_given?
          _with_target facet do 
            instance_eval &blk
          end
        end

        # Register it.
        facet.register_prototype!

        # Add it to this plugin.
        @plugin.facets << facet

        facet
      end

   
      # Define a new command.
      def define_command name, opts = nil, &blk
        opts = _take_doc(opts)
        # $stderr.puts "@target = #{@target.inspect}"
        # $stderr.puts "define_command #{name.inspect}, #{opts.inspect}"

        cmd = _command_manager.define_command(name, opts, &blk)

        cmd._defined_in = @plugin

        @plugin.commands << cmd

        cmd
      end
      alias :cmd :define_command


      # Creates a new command group.
      def define_command_group name, opts = nil, &blk
        opts = _take_doc(opts)
        # $stderr.puts "@target = #{@target.inspect}"
        # $stderr.puts "define_command_group #{name.inspect}, #{opts.inspect}"
 
        cmd = _command_manager.define_command_group(name, opts)

        cmd._defined_in = @plugin

        @plugin.commands << cmd

        _with_target cmd.subcommands, &blk

        cmd
      end
      alias :cmd_group :define_command_group


      private

      def _take_doc opts = nil
        opts = { :documentation => opts } if String === opts
        opts ||= { }
        if text = @doc
          if opts[:documentation]
            $stderr.puts "cabar: warning doc and :documentation defined at #{caller[1]}"            
          end
          @doc = nil
        end
        text ||= @default_doc
        opts[:documentation] = text if text
        opts
      end


      def _with_target object
        @target_stack.push @target
        @target = object
        yield
      ensure
        @target = @target_stack.pop
      end


      # Gets the current command manager depending
      # on the target.
      def _command_manager
        case @target
        when Cabar::Command::Manager
          cmd_mgr = @target
        else
          # Default to top-level command.
          cmd_mgr = Cabar::Main.current.commands
        end

        # $stderr.puts "cmd_mgr = #{cmd_mgr.inspect}"

        cmd_mgr
      end

    end # class

  end # class

end # module

