require 'cabar/component'

require 'cabar/version'
require 'cabar/version/requirement'


module Cabar
  class Component

    # Set of selected components by name.
    # Each component name has a version set.
    #
    # Constraints can be applied to the set.
    #
    # This occurs during component version selection
    # or depenency resolution.
    #
    # See Cabar::Context for usages.
    #
    # It responds to most Enumerable methods as expected.
    #
    class Set
      # List of constraints applied to this set.
      attr_reader :selections

      def initialize avail
        @a = avail
        @set_by_name = nil
        @selections = { }
      end
      
      # Forces coersion to an Array.
      def to_a
        @to_a ||=
        begin
          s = Cabar::Version::Set.new 
          @set_by_name.values.each do | n_s |
            s.push(*n_s)
          end
          s.to_a
        end
      end
      
      # Returns true if x is in this set.
      def include? x
        to_a.include? x
      end

      def join *args
        to_a.join(*args)
      end

      # Returns a Hash that maps component names to
      # a Cabar::Version::Set for components of that name.
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
      
      # Returns the set_by_name Hash.
      def to_hash
        set_by_name
      end
      
      # Apply block to each component.
      def each &blk
        set_by_name.each do | name, version_set |
          yield name, version_set unless version_set.empty?
        end
      end
      
      # Returns the Version::Set for a component name.
      def set_for_name name
        set_by_name[name] ||=
          @a.select(:name => name)
      end

      # Returns a set of components by name or contrstaint.
      def [](constraint)
        return constraint unless constraint
        case constraint
        when String, Symbol
          set_for_name constraint.to_s
        else
          @s.select(constraint)
        end
      end

      
      def _prepare_opts opts
        opts =
        case opts
        when Cabar::Constraint
          opts
        when Cabar::Component
          opts.to_constraint
        else
          Cabar::Constraint.create opts
        end
        
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
            s.push(*r.to_a)
          end
          s
        end

        @to_a = nil
        
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
            s.push(*r.to_a)
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

