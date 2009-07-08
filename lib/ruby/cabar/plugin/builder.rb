require 'cabar/plugin'


require 'cabar/command/helper' # Standard command support.
require 'cabar/facet/standard' # Cabar::Facet::Path


module Cabar

  # Plugin object for gracefully adding new functionality
  # to Cabar
  class Plugin

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
      

      # Returns the Plugin Manager.
      def manager
        @plugin.manager
      end


      # Returns the current Main objects.
      def main
        Cabar::Main.current
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

        # @plugin.commands << cmd

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

