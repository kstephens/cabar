require 'cabar/base'

require 'cabar/error'
require 'cabar/command'
require 'cabar/command/state'


module Cabar
  class Command

    # Parses command-line arguments and executes a command.
    class Runner < Base
      # Cabar::Main object.
      attr_accessor :context
      
      # Cabar::Command::State
      attr_accessor :state
      
      # Cabar::Command resolved by parse_args.
      attr_accessor :cmd
      
      # Cabar::Command::Manager to resolve top-level commands.
      attr_accessor :manager

      # Returns the Cabar::Command::Manager
      def manager
        @manager ||= 
          context.commands
      end
      
      # Parses arguments from command line.
      def parse_args args
        
        state = self.state = State.factory.new
        state.args = args.dup
        
        options = state.cmd_opts
        manager = self.manager
        
        until args.empty?
          arg = args.shift
          
          case arg
          when '--'
            state.cmd_args = args
            args = EMPTY_HASH
          when /^--?([^\s=]+)=(.+)$/
            options[$1.sub(/[^A-Z0-9]/i, '_').to_sym] = $2.dup
          when /^--?([^\s=]+)=$/
            options[$1.sub(/[^A-Z0-9]/i, '_').to_sym] = args.shift
          when /--?([^\s+=]+)$/
            options[$1.sub(/[^A-Z0-9]/i, '_').to_sym] = true
          else
            # Check for command.
            # puts "cmd_path = #{state.cmd_path.inspect}"
            # puts "manager = #{manager.inspect}"
            if ! manager.empty?
              cmd_name = arg.to_s
              state.cmd_path << cmd_name
              if self.cmd = manager.command_by_name[cmd_name]
                manager = self.cmd.subcommands
              else
                raise Cabar::Error, "Invalid command path #{state.cmd_path.inspect}"
              end
            else
              args.unshift arg
              state.cmd_args = args
              args = EMPTY_ARRAY
            end
          end
        end
        
        if state.cmd_path.empty?
          parse_args [ 'help', '--error=', 'command not specified'  ]
        end
        
        # $stderr.puts "state = #{state.inspect}"
        
        self
      end
      
      
      # Executes the selected Command.
      def run
        begin
          cmd = self.cmd
          
          unless cmd
            raise Cabar::Error, "Invalid command name #{state.cmd_path.inspect}"
          end
          
          # Command is not executable?
          unless cmd.proc
            parse_args [ 'help', '--error=', 'command has subcommands', *state.cmd_path ]
            return run 
          end

          # Clone the Command object.
          # $stderr.puts "original cmd = #{cmd.inspect}"
          cmd = cmd.dup
          
          # Attach to the context.
          cmd.main = @context
          
          # Merge the current state.
          state.merge! cmd.state
          
          # Attach to this cmd state.
          state_save = cmd.state
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
        rescue SystemExit => err
          raise err
        rescue Exception => err
          state.exit_code = 10
          $stderr.puts Cabar::Error.cabar_format(err)
        ensure 
          cmd.state = state_save
        end
        
        state.exit_code
      end # run

    end # class

  end # class

end # module

