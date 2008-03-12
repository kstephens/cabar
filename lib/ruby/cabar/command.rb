require 'cabar/base'

require 'cabar/error'


module Cabar
  # Represents commands that can be run from Cabar::Main.
  class Command < Base

    # Attributes during invokation.
    attr_accessor :state
    # The full ARGV.
    def args     ; @state.args;     end
    # The actual command path given.
    def cmd_path ; @state.cmd_path; end
    # The command arguments.
    def cmd_args ; @state.cmd_args; end
    # The command options.
    def cmd_opts ; @state.cmd_opts; end

    # The primary command name.
    attr_accessor :name

    # Alternate names for this command.
    attr_accessor :aliases

    # The documentation for the command.
    attr_accessor :documentation

    # The Proc to be executed.
    attr_accessor :proc

    # The Command that holds this as a subcommand.
    attr_accessor :supercommand

    # A CommandManager for subcommands.
    attr_accessor :subcommands

    # The context that undefined methods will delegate to.
    attr_accessor :main

    def initialize *args, &blk
      @state = State.factory.new
      @subcommands = Manager.factory.new(:owner => self)
      super
      instance_eval if block_given?
    end

    def deepen_dup!
      super
      @state = @state.dup
      self
    end

    # Returns all the valid names and aliases for this command.
    def names
      @aliases.dup << @name
    end

    # Returns true if matches by name or alias.
    def === x
      case x
      when String
        x === @name || @aliases.any?{|x| n === x} 
      when Array
        path = names_path.dup
        x.all? do | x |
          p = path.shift
          p.nil? || p.any?{|p| x === p }
        end
      when
        false
      end
    end

    # Returns the lines of documentation.
    def documentation_lines
      @documentation_lines ||= @documentation.split("\n")
    end

    # Return the full path to this command.
    def name_path
      @name_path ||=
        begin
          path = @supercommand ? @supercommand.name_path.dup : [ ] 
          path.push name
        end
    end

    # Returns the path via aliases to this command.
    # Array of name aliases Arrays.
    def names_path
      @names_path ||=
        begin
          path = @supercommand ? @supercommand.names_path.dup : [ ] 
          path.push names
        end
    end

    # The full name for this command.
    def name_full
      name_path.join(' ')
    end


    # Returns the synopsis of this command from
    # the first line of documentation.
    def synopsis
      "#{name_full} " + documentation_lines[0]
    end

    # Returns the description of this command from
    # the second line of documentation.
    def description
      documentation_lines[1]
    end

    # Returns true if this command is a top-level command.
    def top_level_command?
      ! @supercommand
    end

    # Defer to @main.
    def method_missing sel, *args, &blk
      @main.send(sel, *args, &blk)
    end

    # Trap for bogus commands.
    def execute_command!
      raise Error, "Command instance #{self.inspect} must define execute_command!"
    end

    ##################################################################

    # Define a subcommand.
    def define_command name, opts = nil, &blk
      opts = { :documentation => opts } unless Hash === opts
      opts[:supercommand] = self
      cmd = @subcommands.define_command name, opts, &blk
      cmd
    end
    alias :cmd :define_command

    # Define a subcommand group.
    def define_command_group name, opts = nil, &blk
      opts = { :documentation => opts } unless Hash === opts
      opts[:supercommand] = self
      cmd = @subcommands.cmd_group name, opts, &blk
      cmd
    end
    alias :cmd_group :define_command_group
  
    def inspect
      "#<#{self.class} #{object_id} #{name.inspect} #{aliases.inspect} #{description.inspect}>"
    end

  end # class

end # module


# Circular dependencies.
require 'cabar/command/manager'
require 'cabar/command/state'
