require 'minitest/autorun'
require 'xkeys'

class TestXK_03 < MiniTest::Unit::TestCase

    def test_hash_set_auto
	h = {}.extend XKeys::Set_Auto

	assert_respond_to(h, :[]=)

	h[:a] = 'a'
	assert_equal({ :a => 'a' }, h, "h[:a] = 'a'")

	h.clear; h[:a, :b] = 'ab'
	assert_equal({ :a => { :b => 'ab' }}, h, "h[:a, :b] = 'ab'")

	h.clear; h[1, 2] = '12'
	assert_equal({ 1 => [ nil, nil, '12' ]}, h, "h[1, 2] = '12'")
    end

    def test_array_set_auto
	a = [].extend XKeys::Set_Auto

	assert_respond_to(a, :[]=)

	a[0] = '0'
	assert_equal(['0'], a, "a[0] = '0'")

	a.clear; a[0, :a] = '0:a'
	assert_equal([ { :a => '0:a' } ], a, "a[0, :a] = '0:a'")

	a.clear; a[0, 1] = '01'
	assert_equal([ [ nil, '01' ] ], a, "a[0, 1] = '01'")

	a[0, :[]] = '02'
	assert_equal([ [ nil, '01', '02' ] ], a, "a[0, :[]] = '02'")

	a.clear; a[0] = ?0; a[:[], 1] = ?1;
	assert_equal([ ?0, [ nil, ?1 ] ], a, "a[:[], 1]")
    end

end

# END
