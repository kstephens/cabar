require 'cabar/base'

require 'cabar/configuration'
require 'cabar/loader'
require 'cabar/resolver'
require 'cabar/plugin'
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
      @@current || raise(Error, "Cabar::Main not initialized")
    end


    def initialize *args
      @commands = Command::Manager.factory.
        new(:main => self, 
            :owner => self)

      @_logger = Logger.factory.
        new(:name => 'cabar')

      super

      @@current = self
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
        Plugin::Manager.factory.new(:main => self)
    end


    ##################################################################
    # Command runner
    #

    # The cached Cabar::Command::Runner that handles parsing arguments
    # and running the selected command.
    def command_runner
      @command_runner ||= 
        begin
          # Force loading of plugins.
          resolver.available_components

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
      notify_observers :before_run

      command_runner.run
    ensure
      notify_observers :after_run
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

