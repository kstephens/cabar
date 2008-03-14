require 'cabar/component'

require 'cabar/version'
require 'cabar/version/requirement'


module Cabar
  class Component

    # Set of selected components by name.
    # Each component name has a version set.
    class Set
      # List of constraints applied to this set.
      attr_reader :selections

      def initialize avail
        @a = avail
        @set_by_name = nil
        @selections = { }
      end
      
      def to_a
        s = Cabar::Version::Set.new 
        @set_by_name.values.each do | n_s |
          s.push *n_s
        end
        s.to_a
      end
      
      def include? x
        to_a.include? x
      end

      def join *args
        to_a.join *args
      end

      def set_by_name
        @set_by_name ||=
        begin
          @set_by_name = { }
          @a.map { | c | c.name }.uniq.each do | name |
            set_for_name name
          end
          @set_by_name
        end
      end
      
      def to_hash
        set_by_name
      end
      
      # Apply block to each component.
      def each &blk
        set_by_name.each do | name, version_set |
          yield name, version_set unless version_set.empty?
        end
      end
      
      def set_for_name name
        set_by_name[name] ||=
          @a.select(:name => name)
      end

      # Returns a set of components by name.
      def [](name)
        return name unless name
        set_for_name name.to_s
      end

      
      def _prepare_opts opts
        case opts
        when Cabar::Component
          opts = { :name => opts.name, :version => opts.version }
        end
        opts = Cabar::Constraint.create opts
        
        opts
      end
      

      # Reduces the set of components based on a constraint.
      def select! opts, &blk
        opts = _prepare_opts opts
        
        if name = opts.name
          (@selections[name] ||= [ ]) << opts.dup
          s = set_for_name name
          s.select! opts, &blk
        else
          s = Cabar::Version::Set.new
          @selections.each do | name, version_set |
            x = opts.dup
            x.name = name
            r = select! x, &blk
            s.push *r.to_a
          end
          s
        end
        
        s
      end
      

      # Returns a new set as constrained.
      def select opts, &blk
        opts = _prepare_opts opts
        if name = opts.name
          s = set_for_name name
          s = s.select opts, &blk
        else
          s = Cabar::Version::Set.new
          each do | name, version_set |
            x = opts.dup
            x.name = name
            r = select x, &blk
            s.push *r.to_a
          end
          s
        end
        s
      end
      
      # Find a components matching a constraint.
      def find opts, &blk
        opts = _prepare_opts opts
        if name = opts.name
          s = set_for_name name
          s.find opts, &blk
        else
          @a.find opts, &blk
        end
      end
      
      def inspect
        components = set_by_name.values.map { | x | x.to_a }.flatten
        "#<#{self.class} #{components.inspect}>"
      end
    end # class

  end # class

end # module

