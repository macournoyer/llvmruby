require 'llvmruby'

class Fixnum
  def llvm
    LLVM::Value.get_constant(self)
  end
end

module LLVM
end
