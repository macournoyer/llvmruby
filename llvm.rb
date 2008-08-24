require 'llvmruby'

class Fixnum
  def llvm
    LLVM::Value.get_constant(self)
  end
end

class Float
  def llvm
    LLVM::Value.get_float_constant(self)
  end
end

def testf
  Function.new('shaka', Type::Int32Ty, [Type::Int32Ty])
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

    def write(&b)
      instance_eval(&b)
    end
  end
end
