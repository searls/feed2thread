require "test_helper"

class TestFeed2Thread < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Feed2Thread::VERSION
  end
end
