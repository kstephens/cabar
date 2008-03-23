require 'cabar/base'


module Cabar

  # Base class for rendering methods of Components and Facets.
  class Renderer < Base
    # Controlls how verbose output should be.
    attr_accessor :verbose
    
    # The IO object for puts, defaults to $stdout.
    attr_accessor :output
    
    def initialize *args
      @output ||= $stdout
      super
    end
    
    # Same as output.puts *args.
    def puts *args
      @output.puts(*args)
    end

    # Multimethod dispatching based on first argument's
    # ancestors.
    #
    # For example:
    # 
    #   renderer.render 4, :xyz
    #
    # Would attempt to send:
    #
    #   renderer.render_Fixnum 4, :xyz
    #   renderer.render_Integer 4, :xyz
    #   renderer.render_Precision 4, :xyz
    #   renderer.render_Numeric 4, :xyz
    #   renderer.render_Comparable 4, :xyz
    #   renderer.render_Object 4, :xyz
    #
    # Kernel is avoided and namespaces are removed from ancestor names.
    def render x, *args
      x.class.ancestors.each do | cls |
        next if cls == Kernel
        meth = "render_#{cls.name.sub(/^.*::/, '')}" 
        return send(meth, x, *args) if respond_to? meth
      end
      raise ArgumentError, "Cannot find render_* for #{x.class}"
    end


    # Multimethod dispatching based on common ancestors
    # of all elements in the Array.
    #
    # For example:
    # 
    #   x = [ 4, 4.5 ]
    #   renderer.render x, :xyz
    #
    # Would attempt to send:
    #
    #   renderer.render_Array_Precision x, :xyz
    #   renderer.render_Array_Numeric x, :xyz
    #   renderer.render_Array_Comparable x, :xyz
    #   renderer.render_Array_Object x, :xyz
    #
    # Kernel is avoided and namespaces are removed from ancestor names.
    def render_Array x, *args
      # Get a set of common ancestors.
      ancestors = x.inject(x.first.class.ancestors) do | a, xi | 
        a & xi.class.ancestors
      end

      # Find first method for ancestor named "render_Array_<<ancestor>>".
      ancestors.each do | cls |
        next if cls == Kernel
        meth = "render_Array_#{cls.name.sub(/^.*::/, '')}" 
        return send(meth, x, *args) if respond_to? meth
      end

      raise ArgumentError, "Cannot find render_Array_* for #{x.class}"
    end

  end # class
  
end # module


# TODO: Remove when clients expliclity require this module.
require 'cabar/renderer/yaml'
require 'cabar/renderer/env_var'

