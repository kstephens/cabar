require 'cabar/base'

require 'cabar/context'
require 'cabar/command/manager'
require 'cabar/command/runner'
require 'cabar/command/builtin'


module Cabar

  # Main bin/cbr script object.
  class Main < Base
    # Raw command line arguments from bin/cbr.
    attr_accessor :args

    # The Cabar::Command::Manager for top-level commands.
    attr_accessor :commands

    def initialize *args
      @commands = Command::Manager.factory.new(:main => self)
      super
      define_commands!
    end

    ##################################################################
    # Command runner
    #

    # The Cabar::Command::Runner that handles parsing arguments
    # and running the selected command.
    def command_runner
      @command_runner ||= 
        Command::Runner.factory.new(:context => self)
    end

    # Interface for bin/cbr.
    def parse_args args = self.args
      command_runner.parse_args(args)
    end

    # Interface for bin/cbr.
    def run
      command_runner.run
    end

    ##################################################################

    # Return the Cabar::Context object.
    def context
      @context ||=
      begin
        Context.factory.
          new(:main => self,
              :directory => File.expand_path('.')).
          make_current!
      end
    end


    ##################################################################

    # Hook for defining standard top-level commands.
    def define_commands!
      commands.define_top_level_commands!
    end


  end # class

end # module

