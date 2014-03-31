require 'minitest/autorun'
require 'xkeys'

module MyNew

    def xkeys_new (*args); "abcde"; end

end

class TestXK_05 < MiniTest::Unit::TestCase

    def test_xkeys_new
	a = [].extend(XKeys::Set_Auto).extend(MyNew)
	a[0, 2] = 'X'
	assert_equal([ "abXde" ], a, "a[0, 2] = 'X'")
    end

end
