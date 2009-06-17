require 'cabar/base'

require 'cabar/multimethod'

module Cabar

  # Base class for rendering methods of Components and Facets.
  class Renderer < Base
    include Cabar::Multimethod

    # Controls how verbose output should be.
    attr_accessor :verbose
    
    # The IO object for puts, defaults to $stdout.
    attr_accessor :output
    
    def initialize *args
      @output ||= $stdout
      super
    end
    

    def _logger
      @_logger ||=
        Cabar::Logger.new(:name => self.class.name,
                          :delegate => super)
    end


    # Same as output.puts *args.
    def puts *args
      @output.puts(*args)
    end


    # Define render_* dispatching methods.
    multimethod :render


    # Default Selection rendering method.
    # Renders via #render_Array_of_Component on Selection#to_a.
    def render_Selection x, *args
      render x.to_s, *args
    end

  end # class
  
end # module


# TODO: Remove when clients expliclity require this module.
require 'cabar/renderer/yaml'
require 'cabar/renderer/env_var'

