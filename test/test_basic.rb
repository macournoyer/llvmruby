require 'test/unit'
require 'llvmruby'

include LLVM

class Fixnum
  def llvm
    Value.get_constant(self)
  end
end

class BasicTests < Test::Unit::TestCase
  def setup
    @f = Function.new
    @b = @f.create_block.builder
  end

  def test_simple
    tmp = @b.create_add(23.llvm, 42.llvm)
    @b.create_return(tmp)
    @f.compile
    assert_equal(65, @f.call(0))
  end

  def test_bin_ops
    tmp = @b.bin_op(Instruction::Add, 2.llvm, 3.llvm)
    @b.create_return(tmp)
    @f.compile
    assert_equal(5, @f.call(0))
  end

  def test_udiv
    tmp = @b.bin_op(Instruction::UDiv, 27.llvm, 3.llvm)
    @b.create_return(tmp)
    @f.compile
    assert_equal(9, @f.call(0))
  end
end
