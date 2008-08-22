require 'llvmruby'

class Fixnum
  def llvm
    LLVM::Value.get_constant(self)
  end
end

module LLVM
  class Builder
    def self.add_bin_op(op)
      define_method(op.downcase) do |x, y|
        bin_op(Instruction.const_get(op), x, y)
      end
    end
    
    bin_ops = ['Add', 'Sub', 'Mul', 'UDiv', 'SDiv', 'FDiv', 'URem', 'SRem', 'FRem']
    bin_ops += ['Shl', 'LShr', 'AShr', 'And', 'Or', 'Xor']
    bin_ops.each {|op| add_bin_op(op)}
  end
#HANDLE_BINARY_INST( 7, Add  , BinaryOperator)
#HANDLE_BINARY_INST( 8, Sub  , BinaryOperator)
#HANDLE_BINARY_INST( 9, Mul  , BinaryOperator)
#HANDLE_BINARY_INST(10, UDiv , BinaryOperator)
#HANDLE_BINARY_INST(11, SDiv , BinaryOperator)
#HANDLE_BINARY_INST(12, FDiv , BinaryOperator)
#HANDLE_BINARY_INST(13, URem , BinaryOperator)
#HANDLE_BINARY_INST(14, SRem , BinaryOperator)
#HANDLE_BINARY_INST(15, FRem , BinaryOperator)
#// Logical operators (integer operands)
#HANDLE_BINARY_INST(16, Shl  , BinaryOperator) // Shift left  (logical)
#HANDLE_BINARY_INST(17, LShr , BinaryOperator) // Shift right (logical)
#HANDLE_BINARY_INST(18, AShr , BinaryOperator) // shift right (arithmetic)
#HANDLE_BINARY_INST(19, And  , BinaryOperator)
#HANDLE_BINARY_INST(20, Or   , BinaryOperator)
#HANDLE_BINARY_INST(21, Xor  , BinaryOperator)
end
