# -*- ruby -*-

require 'cabar'

require 'cabar/test/name_version'


describe Cabar::Version::Set do
  NameVersion = Cabar::Test::NameVersion
 
  before do
    @s = Cabar::Version::Set.new
    @foo_1_0 = NameVersion.new(:name => 'foo', :version => '1.0')
    @foo_1_0_dup = NameVersion.new(:name => 'foo', :version => '1.0')
    @foo_1_1 = NameVersion.new(:name => 'foo', :version => '1.1')
    @bar_1_0 = NameVersion.new(:name => 'bar', :version => '1.0')
    @bar_1_1 = NameVersion.new(:name => 'bar', :version => '1.1')
  end

  def add_objects
    @s << @bar_1_0
    @s << @foo_1_1
    @s << @foo_1_0
    @s << @foo_1_0_dup # dup

    @s << @bar_1_0 # dup
    @s << @bar_1_1
  end

  def check_sorted name, s = nil
    # $stderr.puts "s = #{s.inspect}"
    # $stderr.puts "@s = #{@s.inspect}"
    s ||= @s.to_a
    # $stderr.puts "s = #{s.inspect}"
    s.should be_an_instance_of(Array)

    xs = s.select do | x | 
      name === x.name
    end

    xs.size.should >= 2

    xs.inject(Cabar::Version.create('99.99')) do | v, x |
      v.should >= x.version
      x.version
    end
  end

  it "should be empty" do 
    @s.empty?.should == true
    @s.size.should == 0
  end

  it "should have an empty array" do 
    @s.to_a.empty?.should == true
    @s.to_a.size.should == 0
  end

  it 'should be mutable' do
    add_objects
  end

  it 'should avoid duplicates' do
    add_objects
    @s.size.should == 4
  end

  it 'should return sorted versions' do
    add_objects
    check_sorted 'foo'
    check_sorted 'bar'
  end
  
  it 'should dup as sorted' do
    add_objects
    @s.instance_variable_get(:@sorted).should == false
    @s._sort!
    @s.instance_variable_get(:@sorted).should == true

    s = @s.dup
    s.instance_variable_get(:@sorted).should == true
    s.to_a.object_id.should_not == @s.to_a.object_id
  end

  it 'should filter out versions accumulatively' do
    add_objects

    @s.select! :name => 'foo'
    @s.size.should == 2
    check_sorted 'foo'

    @s.select! :version => Cabar::Version.create('1.1')
    @s.size.should == 1
    
    x = @s.first
    x.name.should == 'foo'
    x.version.to_s.should == '1.1'
  end


  it 'should filter out versions' do
    add_objects

    s = @s.select(:name => 'bar', :version => Cabar::Version.create('1.0'))
    s.size.should == 1
    
    x = s.first
    x.name.should == 'bar'
    x.version.to_s.should == '1.0'

    # Original is not mutated.
    @s.size.should >= 1
  end

end


