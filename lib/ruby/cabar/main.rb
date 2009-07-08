require 'cabar/base'

require 'cabar/configuration'
require 'cabar/loader'
require 'cabar/resolver'
require 'cabar/plugin/manager'
require 'cabar/command/manager'
require 'cabar/command/runner'
require 'cabar/observer'
require 'cabar/logger'


module Cabar

  # Main bin/cbr script object.
  class Main < Base
    include Cabar::Observer::Observed

    # Raw command line arguments from bin/cbr.
    attr_accessor :args

    # The global Cabar::Configuration object.
    attr_accessor :configuration

    # The Cabar::Command::Manager for top-level commands.
    attr_accessor :commands

    # The global Cabar::Resolver that contains the available_components.
    # Cabar::Selection will clone this for each Command object.
    attr_accessor :resolver

    # The Cabar::Plugin::Manager manages all plugins.
    attr_accessor :plugin_manager

    # The Cabar::Logger object.
    attr_accessor :_logger


    # Returns the global Main instance.
    def self.current
      Thread.current[:'Cabar::Main.current'] || 
        raise(Error, "Cabar::Main not initialized")
    end


    def as_current
      save_current = Thread.current[:'Cabar::Main.current']
      Thread.current[:'Cabar::Main.current'] = self
      yield self
    ensure
      Thread.current[:'Cabar::Main.current'] = save_current
    end


    def initialize *args, &blk
      @_logger = Logger.factory.
        new(:name => 'cabar')

      super

      if block_given? 
        as_current do
          instance_eval &blk
        end
      end
    end


    ###########################################################
    # Configuration
    #

    # Returns the cached Cabar::Configuration object.
    def configuration
      @configuration ||= 
        Cabar::Configuration.new
    end


    ###########################################################
    # Loader
    #

    # Returns the component loader.
    def loader
      @loader ||= 
        begin
          @loader = Cabar::Loader.factory.
            new(:main => self,
                :configuration => configuration)

          # Prime the component search path queue.
          @loader.add_component_search_path!(configuration.component_search_path)
          
          @loader
        end
    end


    ###########################################################
    # Plugin
    #

    # Returns the cached Cabar::Plugin::Manager object.
    def plugin_manager
      @plugin_manager ||=
        begin
          @@plugin_manager ||=
            Plugin::Manager.factory.new(:main => self)
          x = @@plugin_manager # .dup
          x.main = self
          x
        end
    end


    ##################################################################
    # Command
    #

    def commands
      @commands ||= 
        begin
          @@commands ||= 
            Command::Manager.factory.
            new()
          x = @@commands # .dup
          x
        end
    end


    # The cached Cabar::Command::Runner that handles parsing arguments
    # and running the selected command.
    def command_runner
      @command_runner ||= 
        begin
          # Force loading of plugins.
          resolver.available_components

          @command_runner = new_command_runner
          
          @command_runner
        end
    end


    def new_command_runner
      Command::Runner.factory.new(:main => self, :manager => commands)
    end


    # Interface for bin/cbr.
    def parse_args args = self.args
      command_runner.parse_args(args)
    end


    # Executes the command parsed by #parse_args.
    # Returns the exit_code of the command.
    def run
      notify_observers :before_run

      @exit_code = command_runner.run
    ensure
      notify_observers :after_run
    end


    # Returns the exit_code of the last command executed.
    def exit_code
      @exit_code
    end


    ##################################################################
    # Main Resolver
    #

    # Return the Cabar::Resolver object.
    def resolver
      @resolver ||=
      begin
        @resolver = new_resolver

        # Force loading of cabar itself early.
        @resolver.load_component!(Cabar.cabar_base_directory, 
                                 :priority => :before, 
                                 :force => true)

        @resolver
      end
    end


    # Returns a new Resolver.
    def new_resolver opts = { }
      opts[:main] ||= self
      opts[:configuration] ||= configuration
      opts[:directory] ||= File.expand_path('.')
      Resolver.factory.new(opts)
    end



    ##################################################################


    def inspect
      to_s
    end

  end # class

end # module

