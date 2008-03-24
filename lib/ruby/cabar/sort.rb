
require 'cabar'

module Cabar

  # Sorting functions.
  module Sort

    # Takes a list of elements and :dependents => Proc { | element |  } option.
    #
    # Will sort elements such that and element e1 will be
    # after e2 if e1 is in dependents.call(e2) decendents.
    #
    # dependents Proc is is expected to return an Array.
    #
    # May not complete if elements are cyclical.
    def topographic_sort elements, opts = EMPTY_HASH
      # Get a Proc that returns the dependents of an element.
      # The proc must return an enumeration that can be perform :reverse.
      dependents_proc = opts[:dependents] || raise("No :dependents option")
      
      # The depth of given element in the graph.
      depth = { }
      
      # The queue containing each element and its current depth.
      queue = elements.reverse.map { | e | [ e, 1 ] }
      
      # Until the queue is empty,
      until queue.empty?
        # Get the element and it's current depth in the graph.
        e, d = queue.pop
        # puts "e = #{e.inspect} d = #{d.inspect}"
        
        # Update the elements depth based on the current depth.
        if (! depth[e]) || (depth[e] < d)
          depth[e] = d
        end
        
        # Put dependents at end of queue with a depth greater
        # than current element's depth.
        d = d + 1
        queue[0, 0] = (dependents_proc.call(e).reverse.map { | e | [ e, d ] })
      end
      
      # Create a tie-breaker ordering proc
      # that returns -1, 0, 1 for two elements.
      #
      # The default ordering proc will produce a stable sort
      # of the input.
      order = nil
      order_proc = opts[:order] || lambda do | x, y |
        order ||=
          elements.inject({ }) { | h, e | h[e] ||= h.size; h }
        order[x] <=> order[y]
      end
      
      #puts "elements = #{elements.inspect}"
      #puts "depth = #{depth.inspect}"
      #puts "order = #{get_order.call.inspect}"
      
      # Sort the elements by relative depth or tie-breaker ordering.
      result = elements.sort do | a, b | 
        #puts "a = #{a.inspect}"
        #puts "b = #{b.inspect}"
        if (x = depth[a] <=> depth[b]) != 0
          x
        elsif (x = order_proc.call(a, b)) != 0
          x
        else
          0
        end
      end
      
      result
    end
    #module_method :sort_topographic

  end # module

end # module

