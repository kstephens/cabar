# -*- ruby -*-

require 'cabar/constraint'

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
    @nvs << (@deb_deb_1_0 = nv.new(:name => 'deb', :version => '1.0', :component_type => 'deb')) 
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
    constraint_count(nil, 7)
  end

  it "should match true" do
    constraint_count true, 7
  end

  it 'should match ""' do
    constraint_count "", 7
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

  it 'should match "deb:deb"' do
    constraint_count 'deb:deb', 1
  end

  it 'should not match ":deb"' do
    constraint_count ':deb', 0
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

  it 'should not match "foo,arch=i386"' do
    constraint_count "foo,arch=i386", 0
  end

end

