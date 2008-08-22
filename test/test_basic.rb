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
end
