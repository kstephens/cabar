require 'cabar/base'

require 'cabar/context'
require 'cabar/plugin'
require 'cabar/command/manager'
require 'cabar/command/runner'


module Cabar

  # Main bin/cbr script object.
  class Main < Base
    # Raw command line arguments from bin/cbr.
    attr_accessor :args

    # The Cabar::Command::Manager for top-level commands.
    attr_accessor :commands

    # The Cabar::Context that manages component resolution.
    attr_accessor :context

    # The Cabar::Plugin::Manager manages all plugins.
    attr_accessor :plugin_manager

    def self.current
      @@current || raise(Error, "Cabar::Main not initialized")
    end

    def initialize *args
      @commands = Command::Manager.factory.
        new(:main => self, 
            :owner => self)

      super
      @@current = self
    end

    def plugin_manager
      @plugin_manager ||=
        Plugin::Manager.factory.new(:main => self)
    end

    ##################################################################
    # Command runner
    #

    # The Cabar::Command::Runner that handles parsing arguments
    # and running the selected command.
    def command_runner
      @command_runner ||= 
        begin
          # Force loading of plugins.
          context.available_components

          @command_runner = Command::Runner.factory.new(:context => self)
          
          @command_runner
        end
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
        @context =
          Context.factory.
          new(:main => self,
              :directory => File.expand_path('.')).
          make_current!

        # Force loading of cabar itself early.
        @context.load_component!(Cabar.cabar_base_directory, 
                                 :priority => :before, 
                                 :force => true)

        @context
      end
    end


    ##################################################################

    def inspect
      to_s
    end

  end # class

end # module

