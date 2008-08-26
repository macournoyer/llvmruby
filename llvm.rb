require 'llvmruby'

class Fixnum
  def llvm(type = LLVM::Type::Int64Ty)
    LLVM::Value.get_constant(type, self)
  end
end

class Float
  def llvm
    LLVM::Value.get_float_constant(self)
  end
end

class LLVM::Value
  def llvm
    self
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

    Instruction.constants.grep(/^ICMP_/) do |pred|
      define_method(pred.downcase) do |x, y|
        create_icmp(Instruction.const_get(pred), x, y)
      end
    end

    def write(&b)
      instance_eval(&b)
    end
  end

  # describe structures used by the ruby 1.8/1.9 interpreters
  module RubyInternals
    FIXNUM_FLAG = 0x1.llvm
    CHAR = Type::Int8Ty
    P_CHAR = Type::pointer(CHAR)
    LONG = Type::Int64Ty
    VALUE = Type::Int64Ty
    P_VALUE = Type::pointer(VALUE)
    ID = Type::Int64Ty
    RBASIC = Type::struct([VALUE, VALUE])
    RARRAY = Type::struct([RBASIC, LONG, LONG, P_VALUE])
    P_RARRAY = Type::pointer(RARRAY)
    RSTRING = Type::struct([RBASIC, LONG, P_CHAR, VALUE])
    P_RSTRING = Type::pointer(RSTRING)
  end

  # include this into the builder to get methods for manipulating ruby values
  module RubyHelpers
    include RubyInternals

    def fixnum?(val)
      self.and(FIXNUM_FLAG, val)
    end

    def num2fix(val)
      shifted = shl(val, 1.llvm)
      xor(FIXNUM_FLAG, shifted)
    end

    def fix2int(val)
      x = xor(FIXNUM_FLAG, val)
      lshr(val, 1.llvm)
    end

    def slen(str)
      val_ptr = create_int_to_ptr(str, P_RSTRING)
      len_ptr = create_struct_gep(val_ptr, 1)
      create_load(len_ptr)
    end

    def alen(ary)
      val_ptr = create_int_to_ptr(ary, P_RARRAY)
      len_ptr = create_struct_gep(val_ptr, 1)
      create_load(len_ptr)
    end

    def aref(ary, idx)
      val_ptr = create_int_to_ptr(ary, P_RARRAY)
      data_ptr = create_struct_gep(val_ptr, 3)
      data_ptr = create_load(data_ptr)
      slot_n = create_gep(data_ptr, idx.llvm)
      create_load(slot_n)
    end

    def aset(ary, idx, set)
      val_ptr = create_int_to_ptr(ary, P_RARRAY)
      data_ptr = create_struct_gep(val_ptr, 3)
      data_ptr = create_load(data_ptr)
      slot_n = create_gep(data_ptr, idx.llvm)
      create_store(set, slot_n)
    end
  end
end
