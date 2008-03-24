# -*- ruby -*-

require 'cabar'

require 'cabar/test/name_version'


describe Cabar::Constraint do
  before do
    nv = Cabar::Test::NameVersion
    @nvs = [ ]
    @nvs << (@foo_1_0 = nv.new(:name => 'foo', :version =>'1.0'))
    @nvs << (@foo_1_0_dup = nv.new(:name => 'foo', :version => '1.0'))
    @nvs << (@foo_1_1 = nv.new(:name => 'foo', :version => '1.1'))
    @nvs << (@food_1_1 = nv.new(:name => 'food', :version => '1.1'))
    @nvs << (@bar_1_0 = nv.new(:name => 'bar', :version => '1.0'))
    @nvs << (@bar_1_1 = nv.new(:name => 'bar', :version => '1.1', :arch => 'i386'))
  end

  def constraint c
    r = Cabar::Constraint.create(c)
    # $stderr.puts "c = #{c.inspect} => #{r.inspect}"
    r
  end

  def constraint_count c, size = nil
    c = constraint c
    result = @nvs.select { | x | c === x }
    result.size.should == size if size
    result
  end

  it "should match nil" do
    constraint_count(nil, 6)
  end

  it "should match true" do
    constraint_count true, 6
  end

  it 'should match ""' do
    constraint_count "", 6
  end

  it 'should match { :name => "foo" }' do
    constraint_count({ :name => "foo" }, 3)
  end

  it "should match 'foo*'" do
    constraint_count 'foo*', 4
  end

  it 'should handle parsing of "name=foo"' do
    c = constraint 'name=foo'
    c.should_not == nil
    c.class.should == Cabar::Constraint
    c.name.should == 'foo'
    c.version.should == nil
    c._options.size.should == 0
  end

  it 'should match "name=foo"' do
    constraint_count 'name=foo', 3
  end

  it 'should match "cabar:name=foo"' do
    constraint_count 'cabar:name=foo', 3
  end

  it 'should match "foo*,arch=i386"' do
    constraint_count "foo*,arch=i386", 0
  end

  it 'should match "arch=i386"' do
    constraint_count "arch=i386", 1
  end

  it 'should match "b*,arch=i386"' do
    constraint_count "b*,arch=i386", 1
  end

end

