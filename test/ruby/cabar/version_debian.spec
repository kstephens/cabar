# -*- ruby -*-

require 'cabar/version/debian'

require 'cabar/test/name_version'


describe Cabar::Version::Debian::Part do
  def create x
    Cabar::Version::Debian::Part.create x
  end

  it 'should handle nil, false' do
    create(nil).should == nil
    create(false).should == false
  end

  it 'should handle Integer' do
    x = create(5)
    x.should_not == nil
    x.to_a.should === [ '', 5 ]
  end

  it 'should handle Array' do
    a = [ '', 1, '.', 2 ]
    x = create(a)
    x.to_a.object_id.should_not == a.object_id
    x.to_a.should == a
    x.to_a.frozen?.should == true
  end

  it 'should handle basic String' do
    v = '01.2.3'
    x = create(v)
    x.to_a.size.should == 6
    x.to_a.should == [ '', 1, '.', 2, '.', 3 ]
    y = create('1.2.3')
    x.should == y
  end


  it 'should compare as equal' do
    v1 = '01.2.3'
    v2 = '1.2.3'
    x1 = create(v1)
    x2 = create(v2)
    x1.to_a.should == [ '', 1, '.', 2, '.', 3 ]
    x2.to_a.should == [ '', 1, '.', 2, '.', 3 ]
    x1.hash.should == x2.hash
    x1.should == x2
  end

  it 'should handle complex versions' do
    v1 = 'foo-1.12.3a'
    v2 = 'foo-1.12.3b'
    x1 = create(v1)
    x2 = create(v2)
    x1.to_a.should == [ 'foo-', 1, '.', 12, '.', 3, 'a', -99999 ]
    x2.to_a.should == [ 'foo-', 1, '.', 12, '.', 3, 'b', -99999 ]
    x1.hash.should_not == x2.hash
    x1.should < x2
    x1.should_not == x2

    v3 = 'foo-1.12'
    x3 = create(v3)
    x3.should < x1
    x3.should < x2
  end
end


describe Cabar::Version::Debian do
  def create x
    Cabar::Version::Debian.create x
  end

  it 'should handle nil, false' do
    create(nil).should == nil
    create(false).should == false
  end

  it 'should handle Integer' do
    x = create(5)
    x.should_not == nil
  end


  it 'should handle complex versions' do
    v1 = create '1.12.3a'
    v2 = create '1.12.3b'
    v3 = create '1.13'
    v4 = create '02.1'
    v5 = create '2.1'

    v1.epoch.should == 0
    v2.epoch.should == 0
    v3.epoch.should == 0
    v4.epoch.should == 0
    v5.epoch.should == 0

    v1.should < v2
    v2.should < v3
    v3.should < v4
    v4.should == v5
  end

  it 'should handle epochs' do
    v1 = create '1.12.3a'
    v2 = create '1:1.12.3a'

    v1.epoch.should == 0
    v2.epoch.should == 1

    v1.should < v2
  end

  it 'should handle debian_revisions' do
    v1 = create '1.12.3a-foo1.2'
    v2 = create '0:1.12.3a-foo1.2'
    v3 = create '1.12.3a-foo1.3'

    v1.epoch.should == 0
    v2.epoch.should == 0
    v3.epoch.should == 0

    v1.should == v2
    v1.should < v3
    v2.should < v3
  end

end


