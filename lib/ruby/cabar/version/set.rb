require 'cabar/version'

require 'cabar/constraint'
require 'forwardable'


module Cabar
  class Version

    # This maintains an ordered set of objects that
    # respond to :name and :version.
    #
    # Set is sorted by name in proper order
    # and version in reverse order.
    #
    # It responds to most Enumerable methods as expected.
    #
    class Set < ::Object
      extend Forwardable
      
      def_delegators :@a, :empty?, :size, :first, :last, :[], :sort

      def each &blk
        _sort!.each &blk
      end

      def map &blk
        _sort!.map &blk
      end
      alias :collect :map

      def inject x, &blk
        _sort!.inject x, &blk
      end

      def initialize list = [ ]
        super()
        @a = list.to_a
        @sorted = false
      end
      
      def dup
        x = self.class.new @a.dup
        x.instance_variable_set(:@sorted, @sorted)
        x
      end
      
      def [](name)
        select name
      end

      # Sorts by newest to latest version.
      def _sort!
        unless @sorted
          @a.sort! do | a, b |
            x = a.name <=> b.name
            if x == 0
              x = b.version <=> a.version
            end
            x
          end
          @sorted = true
        end
        @a
      end
      
      def to_a
        _sort!
      end
      
      def join *args
        to_a.join *args
      end

      def include? x
        ! ! @a.find do | x2 | 
          x2 == x || (
                      x.object_id != x2.object_id &&
                      x.name === x2.name && 
                      x.version === x2.version
                      )
        end
      end

      def push *list
        list.each do | c |
          unless include? c
            @sorted = false
            @a << c        
          end
        end
        self
      end
      
      def << c
        push c
      end
      
      def unshift c
        push c
      end
      
      # Reduces set based on additional constraint.
      def select! opts, &blk
        opts = Cabar::Constraint.create opts

        match = opts.to_proc

        _sort!
        
        @a = @a.select do | obj |
          m = block_given? ? yield(obj) : true
          m && match.call(obj)
        end

        self
      end
      
      def select opts, &blk
        dup.select! opts, &blk
      end
      
      # Find first matching component from list.
      def find opts, &blk
        result = select opts, &blk
        
        if result.size > 1 
          raise "Too many components match #{opts.inspect}: #{result.map{|x| x.version.to_s}.inspect}"
        end
        
        if result.size < 1
          raise "Cannot find component matching #{opts.inspect}"
        end
        
        result.first
      end
      
      def inspect
        components = @a
        "#<#{self.class} #{components.inspect}>"
      end

    end # class

  end # class

end # module

