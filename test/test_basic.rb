require 'test/unit'
require 'llvm'

include LLVM

class BasicTests < Test::Unit::TestCase
  def bin_op(op, v1, v2, expected)
    f = Function.new
    b = f.create_block.builder 
    ret = b.bin_op(op, v1.llvm, v2.llvm)
    b.create_return(ret)
    f.compile
    assert_equal(expected, f.call(0))
  end

  def test_bin_ops
    bin_op(Instruction::Add, 2, 3, 5)
    bin_op(Instruction::Sub, 5, 3, 2)
    bin_op(Instruction::Mul, 2, 3, 6)
    bin_op(Instruction::UDiv, 42, 6, 7)
    bin_op(Instruction::SDiv, 42, 6, 7)
    #bin_op(Instruction::FDiv, 23.0, 5, 0.23)
    bin_op(Instruction::URem, 23, 5, 3)
    bin_op(Instruction::SRem, 23, 5, 3)
    #bin_op(Instruction::FRem, 23.0, 5, 0.23)

    bin_op(Instruction::Shl, 2, 1, 4)
    bin_op(Instruction::LShr, 8, 1, 4)
    #bin_op(Instruction::AShr, 8, 1, 4) 
    bin_op(Instruction::And, 8, 15, 8)
    bin_op(Instruction::Or, 8, 15, 15)
    bin_op(Instruction::Xor, 8, 15, 7)
  end

  def builder_bin_op(op, v1, v2, expected)
    f = Function.new
    b = f.create_block.builder
    ret = b.send(op, v1.llvm, v2.llvm)
    b.create_return(ret)
    f.compile
    assert_equal(expected, f.call(0))
  end

  def test_builder_bin_ops
    builder_bin_op(:add, 23, 42, 65)
    builder_bin_op(:sub, 69, 13, 56)
    builder_bin_op(:mul, 23, 5, 115)
    builder_bin_op(:udiv, 23, 5, 4)
    builder_bin_op(:sdiv, 99, 33, 3)
    #builder_bin_op(:fdiv, 23, 42, 65)
    builder_bin_op(:urem, 23, 42, 23)
    builder_bin_op(:srem, 77, 5, 2)
    #builder_bin_op(:frem, 23, 42, 65)
    builder_bin_op(:shl, 15, 1, 30)
    builder_bin_op(:lshr, 32, 2, 8)
    #builder_bin_op(:ashr, 23, 42, 65)
    builder_bin_op(:and, 32, 37, 32)
    builder_bin_op(:or, 15, 8, 15)
    builder_bin_op(:xor, 33, 15, 46)
  end
end
