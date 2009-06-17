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
    

    def _logger
      @_logger ||=
        Cabar::Logger.new(:name => self.class.name,
                          :delegate => super)
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
        meth = :"render_#{cls.name.sub(/^.*::/, '')}" 
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
    # Would send to the first method where self.respond_to? is true.
    #
    #   renderer.render_Array_of_Precision x, :xyz
    #   renderer.render_Array_of_Numeric x, :xyz
    #   renderer.render_Array_of_Comparable x, :xyz
    #   renderer.render_Array_of_Object x, :xyz
    #
    # Kernel is avoided and namespaces are removed from ancestor names.
    def render_Array x, *args
      # Get a set of common ancestors of all element values.
      val_ancestors = x.inject(x.first.class.ancestors) do | a, xi | 
        a & xi.class.ancestors
      end
      val_ancestors.delete(::Kernel)

      # Find first method for ancestor named "render_Array_<<ancestor>>".
      val_ancestors.each do | cls |
        meth = :"render_Array_of_#{cls.name.sub(/^.*::/, '')}" 
        return send(meth, x, *args) if respond_to? meth
      end

      raise ArgumentError, "Cannot find render_Array_of_* for #{x.class} using common ancestors #{val_ancestors.inspect}"
    end


    # Multimethod dispatching based on common ancestors
    # of all elements in the Hash.
    #
    # For example:
    # 
    #   x = { :a=> 4, :b => 4.5 }
    #   renderer.render x, :xyz
    #
    # Would send to the first method where self.respond_to? is true.
    #
    #   renderer.render_Hash_of_Symbol_and_Precision x, :xyz
    #   renderer.render_Hash_of_Symbol_and_Numeric x, :xyz
    #   renderer.render_Hash_of_Symbol_and_Comparable x, :xyz
    #   renderer.render_Hash_of_Symbol_and_Object x, :xyz
    #   renderer.render_Hash_of_Object_and_Precision x, :xyz
    #   renderer.render_Hash_of_Object_and_Numeric x, :xyz
    #   renderer.render_Hash_of_Object_and_Comparable x, :xyz
    #   renderer.render_Hash_of_Object_and_Object x, :xyz
    #
    # Kernel is avoided and namespaces are removed from ancestor names.
    def render_Hash x, *args
      # Get a set of common ancestors of all key elements.
      key_ancestors = x.keys.inject(x.keys.first.class.ancestors) do | a, xi | 
        a & xi.class.ancestors
      end
      key_ancestors.delete(::Kernel)

      # Get a set of common ancestors of all value elements.
      val_ancestors = x.values.inject(x.values.first.class.ancestors) do | a, xi | 
        a & xi.class.ancestors
      end
      val_ancestors.delete(::Kernel)

      # Find first method for ancestor named "render_Hash_of_<<key_ancestor>>_and_<<val_ancestor>>".
      key_ancestors.each do | key_cls |
        val_ancestors.each do | val_cls |
          meth = :"render_Hash_of_#{key_cls.name.sub(/^.*::/, '')}_and__#{val_cls.name.sub(/^.*::/, '')}" 
          return send(meth, x, *args) if respond_to? meth
        end
      end

      raise ArgumentError, "Cannot find render_Hash_of_*_and_* for #{x.class} using common key ancestors #{key_ancestors.inspect} and value ancestors #{val_ancestors.inspect}"
    end


    # Default Selection rendering method.
    # Renders via #render_Array_of_Component.
    def render_Selection x, *args
      render x.to_s, *args
    end

  end # class
  
end # module


# TODO: Remove when clients expliclity require this module.
require 'cabar/renderer/yaml'
require 'cabar/renderer/env_var'

