require 'minitest/autorun'
require 'xkeys'

class TestXK_04 < MiniTest::Unit::TestCase

    def test_hash
	a = [].extend XKeys::Hash
	assert_kind_of(XKeys::Get, a, 'Hash => Get')
	assert_kind_of(XKeys::Set_Hash, a, 'Hash => Set_Hash')
    end

    def test_auto
	a = [].extend XKeys::Auto
	assert_kind_of(XKeys::Get, a, 'Auto => Get')
	assert_kind_of(XKeys::Set_Auto, a, 'Auto => Set_Auto')
    end

end

# END
