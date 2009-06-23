
module Derby
  EMPTY_ARRAY = [ ].freeze unless defined? EMPTY_ARRAY
  EMPTY_HASH  = { }.freeze unless defined? EMPTY_HASH


  # Mixin to handle:
  #
  #   class Foo
  #     attr_accessor :foo, :bar
  #   end
  #
  #   obj = Foo.new(:foo => 'foo', :baz => 'baz')
  #   obj.foo => 'foo'
  #   obj.bar => 'nil'
  #   obj.options => { :baz => 'baz' }
  #
  module InitializeFromHash
    def options
      @options
    end

    def initialize opts = nil
      opts ||= EMPTY_HASH
      @options = opts.dup
      pre_initialize if respond_to?(:pre_initialize)
      opts.each do | k, v |
        s = :"#{k}="
        if respond_to?(s)
          send(s, v) 
          @options.delete(k)
        end
      end
      post_initialize if respond_to?(:post_initialize)
    end
  end


  module DottedHash
    def method_missing sel, *args, &blk
      sel = sel.to_s
      if args.empty? && ! block_given? && key?(sel)
        self[sel]
      else
        super
      end
    end
  end # module

end # module


# Use to add comp/... directories to search path when its too early for
# cabar to require itself.
def cabar_comp_require name, version = nil
  path = File.expand_path(File.dirname(__FILE__) + "../../../../../../comp/#{name}/#{version}/lib/ruby")
  $:.insert(0, path) unless $:.include?(path)
  # $stderr.puts "#{$:.inspect} #{path.inspect}"
  require name
end


cabar_comp_require 'cabar_core'

