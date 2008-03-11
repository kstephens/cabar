require 'cabar/base'

require 'cabar/error'
require 'cabar/renderer'


module Cabar
  class Command

    # The parsed command line state.
    class State < Base
      # The full ARGV.
      attr_accessor :args
      
      # The parsed command path.
      attr_accessor :cmd_path
      
      # The parsed arguments for the command.
      attr_accessor :cmd_opts
      
      # The arguments for the command
      attr_accessor :cmd_args
      
      # Exit code of command.
      attr_accessor :exit_code
      
      def initialize *args
        @args = [ ]
        @cmd_path = [ ]
        @cmd_args = [ ]
        @cmd_opts = { }
        @exit_code = 0
        super
      end
      
      def deepen_dup!
        super
        @args = @args.dup
        @cmd_path = @cmd_path.dup
        @cmd_args = @cmd_args.dup
        @cmd_opts = @cmd_opts.dup
      end

      def merge! state
        # @args = state.args
        # @cmd_path = state.cmd_path
        @cmd_opts = state.cmd_opts.dup.cabar_merge! @cmd_opts
        # @cmd_args = state.cmd_args
        # @exit_code = state.exit_code
      end

      def inspect
        "#<#{self.class} #{object_id} #{cmd_path.inspect} #{cmd_opts.inspect} #{cmd_args.inspect}>"
      end

    end # class

  end # class

end # module


