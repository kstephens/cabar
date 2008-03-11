require 'cabar/base'

require 'cabar/context'
require 'cabar/command'


module Cabar

  # Main command line driver.
  class Main < Base
    attr_accessor :args

    attr_accessor :commands

    def initialize *args
      @commands = CommandManager.factory.new(:main => self)
      super
      define_commands!
    end

    ##################################################################
    # Command runner
    #

    def runner
      @runner ||= 
        CommandRunner.factory.new(:context => self)
    end

    def parse_args args = self.args
      runner.parse_args(args)
    end

    def run
      runner.run
    end

    ##################################################################

    # Return the Context object.
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

    def define_commands!
      commands.define_top_level_commands!
    end


  end # class

end # module

