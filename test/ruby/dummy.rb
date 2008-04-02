
require 'test/unit'

# This only exists to satisfy Hoe's broken
# :test task that fails if there are no .rb
# files in the test/ directory.
class CabarDummyTest < Test::Unit::TestCase
  def test_dummy
    assert true
  end
end

