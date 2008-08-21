require 'test/unit'
require '../llvmruby'

include LLVM

class BasicTests < Test::Unit::TestCase
  def test_simple
    f = Function.new
    block = f.create_block
    b = block.builder
    x = Value.get_constant(23)
    y = Value.get_constant(42)
    tmp = b.create_add(x, y)
    b.create_return(tmp)
    f.compile
    assert_equal(65, f.call(0))
  end

  def test_simple2
    f = Function.new
    block = f.create_block
    b = block.builder
    x = Value.get_constant(23)
    y = Value.get_constant(42)
    tmp = b.create_add(x, y)
    b.create_return(tmp)
    f.compile
    assert_equal(65, f.call(0))
  end
end
