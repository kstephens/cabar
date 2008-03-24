# -*- ruby -*-

require 'cabar'

# Test target.
require 'cabar/sort'


describe Cabar::Sort do
  include Cabar::Sort

  before do
    # Test
    @children = {
      'a' => [ 'b', 'c' ],
      'b' => [ 'x' ],
      'c' => [ 'x' ],
      'x' => [ 'y' ],
      'y' => [ 'z' ],
      'z' => [ '1', '2' ],
    }
    @children_proc = lambda { | x | @children[x] || [ ] } 
    @unsorted = (@children.keys + @children.values).flatten.uniq
    @sorted = 
      [ 
       # 'b' and 'c' are mutually independent, but depend on 'a'.
       [ 'a', 'b', 'c', 'x', 'y', 'z', '1', '2' ],
       [ 'a', 'b', 'c', 'x', 'y', 'z', '2', '1' ],
       [ 'a', 'c', 'b', 'x', 'y', 'z', '1', '2' ], 
       [ 'a', 'c', 'b', 'x', 'y', 'z', '2', '1' ], 
      ]
  end

  it "sorts random permutations topologically." do
    1000.times do
      permutation = @unsorted.sort { | a, b | rand(10000) <=> rand(10000) }
      result = topographic_sort(permutation, :dependents => @children_proc)
      # puts "permutation = #{permutation.inspect}"
      # puts "  result    = #{result.inspect}"
      @sorted.any? { | x | result === x }.should == true
    end 

  end

  it "sorts permutations with :order option." do
    # With :order.
    sorted = 
      [ 
       @sorted[0]
      ]
    
    1000.times do
      permutation = @unsorted.sort { | a, b | rand(10000) <=> rand(10000) }
      result = topographic_sort(permutation, 
                                :dependents => @children_proc, 
                                :order => lambda { | a, b | a <=> b })
      #puts "permutation = #{permutation.inspect}"
      #puts "  result    = #{result.inspect}"
      @sorted.any? { | x | result === x }.should == true
    end
  end # its

end # describe

