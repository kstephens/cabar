require 'cabar/base'

require 'cabar/error'
require 'cabar/command'
require 'cabar/command/state'

require 'cabar/observer'

module Cabar
  class Command

    # Parses command-line arguments and executes a command.
    class Runner < Base
      include Cabar::Observer::Observed

      # Cabar::Main object.
      attr_accessor :main
      
      # Cabar::Command::Manager to resolve top-level commands.
      attr_accessor :manager

      # Cabar::Command::State
      attr_accessor :state
      
      # Cabar::Command resolved by parse_args.
      attr_accessor :cmd
      

      def _logger
        @main._logger
      end

      # Returns the Cabar::Command::Manager
      def manager
        @manager ||= 
          main.commands
      end
      
      # Parses arguments from command line.
      # Returns self.
      def parse_args args
        orig_args = args

        @parse_args ||= 0
        @parse_args += 1

        # $stderr.puts "  parse_args #{args.inspect}"
        # $stderr.puts "    main #{main}"
        # $stderr.puts "    manager #{manager.inspect}"

        state = self.state = State.factory.new
        # Avoid modifying ARGV and its String elements.
        args = state.args = args.map{|x| x.dup}
        # Avoid modifying state.args during shifts.
        args = args.dup

        options = state.cmd_opts
        manager = self.manager
        
        until args.empty?
          arg = args.shift
          arg = arg.dup rescue arg
          # $stderr.puts "    arg = #{arg.inspect}"

          case arg
          when '--'
            state.cmd_args = args
            args = EMPTY_HASH
          when '-'
            options[_to_sym(EMPTY_STRING)] = args.shift
          when /\A--?([^\s=]+)=(.+)\Z/
            options[_to_sym($1)] = $2
          when /\A--?([^\s=]+)=\Z/
            arg = args.shift
            arg = arg.dup rescue arg
            options[_to_sym($1)] = arg
          when /\A--?([^\s+=]+)\Z/
            options[_to_sym($1)] = true
          when /\A\+\+?([^\s+=]+)\Z/
            options[_to_sym($1)] = false
          else
            # puts "    cmd_path = #{state.cmd_path.inspect}"
            # puts "    manager = #{manager.inspect}"
            # Check for command.
            if ! manager.empty?
              cmd_name = arg.to_s
              state.cmd_path << cmd_name
              if self.cmd = manager.command_for_name(cmd_name)
                manager = self.cmd.subcommands
              else
                raise Cabar::Error, "Invalid command path #{state.cmd_path.inspect}, given arguments #{orig_args.inspect}"
              end
            else
              args.unshift arg
              state.cmd_args = args
              args = EMPTY_ARRAY
            end
          end
        end
        
        if state.cmd_path.empty?
          if @parse_args < 2
            parse_args [ 'help', '--error=', 'command not specified' ]
          else
            raise Error, "Recursion into parse_args?, given arguments #{orig_args.inspect}"
          end
        end

        notify_observers(:command_parse_args_after)

        # $stderr.puts "state = #{state.inspect}"
        
        self
      end
      
      
      def _to_sym x
        x == EMPTY_STRING ? :_ : x.gsub(/[^A-Z0-9]/i, '_').to_sym
      end


      # Executes the selected Command.
      # Returns the exit_code.
      def run
        cmd_state_save = nil

        cmd = self.cmd
        
        unless cmd
          raise Cabar::Error, "Invalid command name #{state.cmd_path.inspect}"
        end
        
        # Command is not executable?
        # Show the help!
        unless cmd.proc
          parse_args [ 'help', '--error=', 'command has subcommands', *state.cmd_path ]
          return run 
        end
        
        # Clone the Command object.
        # $stderr.puts "original cmd = #{cmd.inspect}"
        cmd = cmd.dup
        
        # Attach Command object to Main.
        cmd.main = self.main
        
        # Merge the current state.
        state.merge! cmd.state
        
        # Attach to this cmd state.
        cmd_state_save = cmd.state
        cmd.state = state
        
        # We need to define the singleton method here
        # because singleton methods do not survive
        # dup!
        (class << cmd; self; end).class_eval do 
          define_method :execute_command!, cmd.proc
        end
        
        # $stderr.puts "state = #{cmd.state.inspect}"
        # $stderr.puts "cmd = #{cmd.inspect}"
        # $stderr.puts "cmd.methods = #{cmd.methods.sort.inspect}"
        
        # Execute the command.
        cmd.execute_command!

        # Return the command's exit code.
        cmd.state.exit_code

      ensure 
        cmd.state = cmd_state_save if cmd_state_save
      end # run

    end # class

  end # class

end # module

