$: << File.expand_path(File.dirname(__FILE__) + '/../../../../../lib/ruby')

module Derby
  EMPTY_ARRAY = [ ].freeze unless defined? EMPTY_ARRAY
  EMPTY_HASH  = { }.freeze unless defined? EMPTY_HASH


  # Mixin to handle:
  #
  #   class Foo
  #     attr_accessor :foo, :bar
  #   end
  #
  #   Foo.new(:foo => 'foo')
  #
  module InitializeFromHash
    def initialize opts = nil
      opts ||= EMPTY_HASH
      @options = { }
      pre_initialize if respond_to?(:pre_initialize)
      opts.each do | k, v |
        s = :"#{k}="
        if respond_to?(s)
          send(s, v) 
        else
          @options[k] = v
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

