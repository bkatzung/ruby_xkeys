require 'minitest/autorun'
require 'xkeys'

class TestXK < MiniTest::Unit::TestCase

    def test_hash_get
	h = { :a => 'a', :b => { :c => 'bc' },
	  :d => { :e => { :f => 'def' }}}.extend XKeys::Get

	assert_respond_to(h, :xfetch)
	assert_respond_to(h, :[])

	assert_equal('a', h.xfetch(:a), 'h.xfetch :a')
	assert_equal({ :c => 'bc' }, h.xfetch(:b), 'h.xfetch :b')
	assert_equal('bc', h.xfetch(:b, :c), 'h.xfetch :b, :c')

	assert_equal(false, h.xfetch(:b, :d, :else => false),
	  'h.xfetch :b, :d, :else => false')
	assert_raises(KeyError, 'h.xfetch :b, :d') { h.xfetch :b, :d }

	assert_equal('a', h[:a], 'h[:a]')
	assert_equal({ :c => 'bc' }, h[:b], 'h[:b]')
	assert_equal('bc', h[:b, :c], 'h[:b, :c]')

	assert_equal(false, h[:b, :d, :else=>false], 'h[:b, :d, :else=>false]')
	assert_equal(nil, h[:b, :d], 'h[:b, :d]')
	assert_raises(KeyError, 'h[:b, :d, {:raise=>true}]') do
	    h[:b, :d, {:raise=>true}]
	end
	assert_raises(RuntimeError, 'h[:b, :d, {:raise=>RuntimeError}]') do
	    h[:b, :d, {:raise=>RuntimeError}]
	end
	assert_raises(RuntimeError, 'h[:b, :d, {:raise=>[RuntimeError]}]') do
	    h[:b, :d, {:raise=>[RuntimeError]}]
	end
    end

    def test_array_get
	a = [ '0', [ '1.0' ], [ '2.0', [ '2.1.0', '2.1.1' ]]].extend XKeys::Get

	assert_respond_to(a, :xfetch)
	assert_respond_to(a, :[])

	assert_equal('0', a.xfetch(0), 'a.xfetch 0')
	assert_equal('1.0', a.xfetch(1, 0), 'a.xfetch 1, 0')
	assert_equal('1.0', a.xfetch(1, 0, {}), 'a.xfetch 1, 0, {}')
	assert_equal('2.1.1', a.xfetch(2, 1, 1), 'a.xfetch 2, 1, 1')

	assert_equal(false, a.xfetch(1, 1, :else => false),
	  'a.xfetch 1, 1, :else => false')
	assert_raises(IndexError, 'a.xfetch 1, 1') { a.xfetch 1, 1 }

	assert_equal('0', a[0], 'a[0]')
	assert_equal([['1.0']], a[1, 1], 'a[1, 1]')
	assert_equal('1.0', a[1, 0, {}], 'a[1, 0, {}]')
	assert_equal('2.1.1', a[2, 1, 1], 'a[2, 1, 1]')

	assert_equal(false, a[1, 1, :else=>false], 'a[1, 1, :else=>false]')
	assert_equal(nil, a[1, 1, {}], 'a[1, 1, {}]')
	assert_raises(IndexError, 'a[1, 1, {:raise=>true}]') do
	    a[1, 1, {:raise=>true}]
	end
    end

end

# END
