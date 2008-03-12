require 'cabar/base'

require 'cabar/context'
require 'cabar/facet/standard' # Cabar::Facet::EnvVarPath
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
      @@default_name = x
    end

    # The manager for this plugin.
    attr_accessor :manager

    # Name of this plugin.
    attr_accessor :name

    # Source of this plugin.
    attr_accessor :file

    # Array of Facets defined by this plugin.
    attr_accessor :facets
    
    # Array of commands defined by this plugin.
    attr_accessor :commands

    def initialize *args, &blk
      @file = caller[1]
      @facets = [ ]
      @commands = [ ]

      super

      @file = $1 if /^(.*):\d+:in / === @file
      @name ||= @@default_name

      if block_given?
        build! &blk
      end
    end

    
    def build! &blk
      # Get the main plugin manager.
      @manager ||= Cabar::Main.current.plugin_manager

      # Create a new builder.
      Builder.factory.new(:plugin => self, &blk)

      # Register the plugin.
      @manager.register_plugin! self
    end


    def to_s
      "plugin #{name}"
    end

    # Manages plugins.
    class Manager < Base
      # The Cabar::Main object.
      attr_accessor :main

      # The list of plugins.
      attr_reader :plugins

      attr_reader :plugin_by_name

      def initialize *args
        @plugins = [ ]
        @plugin_by_name = { }
        super
      end

      def register_plugin! plugin
        name = plugin.name.to_s
        if @plugin_by_name[name]
          raise Error, "Plugin named #{name.inspect} already registered."
        end
        @plugins << plugin
        @plugin_by_name[name] = plugin
        self
      end
    end


    # Builder for plugin artifacts.
    class Builder < Base
      # The plugin being built.
      attr_accessor :plugin
      
      def initialize *args, &blk
        @context = nil
        @context_stack = [ ]
        super
        instance_eval &blk if block_given?
      end

      # Define a Facet.
      def facet name, opts = nil, &blk
        opts ||= { }

        opts[:key] = name
        opts[:class] ||= Facet::EnvVarPath
        cls = opts[:class]
        opts.delete(:class)
        opts[:_defined_in] = @plugin

        # Create a new Facet prototype.
        facet = cls.new(opts)

        # Initialize it.
        if block_given?
          _with_context facet do 
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
      def define_command *args, &blk
        # $stderr.puts "@context = #{@context.inspect}"
        # $stderr.puts "define_command #{args.inspect}"

        cmd = _command_manager.define_command *args, &blk

        cmd._defined_in = @plugin

        @plugin.commands << cmd

        cmd
      end
      alias :cmd :define_command


      # Creates a new command group.
      def define_command_group *args, &blk
        # $stderr.puts "@context = #{@context.inspect}"
        # $stderr.puts "define_command_group #{args.inspect}"

        cmd = _command_manager.define_command_group *args

        cmd._defined_in = @plugin

        @plugin.commands << cmd

        _with_context cmd.subcommands, &blk

        cmd
      end
      alias :cmd_group :define_command_group

      private

      def _with_context object
        @context_stack.push @context
        @context = object
        yield
      ensure
        @context = @context_stack.pop
      end

      # Gets the current command manager depending
      # on the context.
      def _command_manager
        case @context
        when Cabar::Command::Manager
          cmd_mgr = @context
=begin
FIXME
        when Cabar::Facet
          # Start at top-level command.
          cmd_mgr = Cabar::Main.current.commands

          # Define a top-level command for the facet unless
          # a top-level command by that name already
          # exists.
          cmd_name = @context.key

          unless top_level_cmd = cmd_mgr.command_by_name[cmd_name]
            top_level_cmd = cmd_mgr.define_command_group cmd_name
          end

          cmd_mgr = top_level_cmd.subcommands
=end
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

