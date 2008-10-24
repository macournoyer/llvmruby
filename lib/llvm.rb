require 'llvmruby'

class Fixnum
  def llvm(type = LLVM::MACHINE_WORD)
    LLVM::Value.get_constant(type, self)
  end
end

class Float
  def llvm
    LLVM::Value.get_float_constant(self)
  end
end

class Object
  def immediate
    LLVM::Value.get_immediate_constant(self)
  end
end

class LLVM::Value
  def llvm
    self
  end

  def immediate
    self
  end
end

module LLVM
  # enum llvm::Type::TypeID
  VoidTyID, FloatTyID, DoubleTyID, X86_FP80TyID, FP128TyID, PPC_FP128TyID, LabelTyID, IntegerTyID, 
  FunctionTyID, StructTyID, ArrayTyID, PointerTyID, OpaqueTyID, VectorTyID = (0..13).to_a
  
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
        icmp(Instruction.const_get(pred), x, y)
      end
    end

    Instruction.constants.grep(/^FCMP_/) do |pred|
      define_method(pred.downcase) do |x, y|
        fcmp(Instruction.const_get(pred), x, y)
      end
    end

    def self.define_cast(name, inst)
      define_method(name) do |val, dest_type|
        cast(inst, val, dest_type)
      end
    end

    define_cast(:trunc,      Instruction::Trunc)
    define_cast(:zext,       Instruction::ZExt)
    define_cast(:sext,       Instruction::SExt)
    define_cast(:fp_to_si,   Instruction::FPToSI)
    define_cast(:fp_to_ui,   Instruction::FPToUI)
    define_cast(:ui_to_fp,   Instruction::UIToFP)
    define_cast(:si_to_fp,   Instruction::SIToFP)
    define_cast(:fp_trunc,   Instruction::FPTrunc)
    define_cast(:fp_ext,     Instruction::FPExt)
    define_cast(:ptr_to_int, Instruction::PtrToInt)
    define_cast(:int_to_ptr, Instruction::IntToPtr)
    define_cast(:bit_cast,   Instruction::BitCast)
 
    def write(&b)
      instance_eval(&b)
    end
  end

  # describe structures used by the ruby 1.8/1.9 interpreters
  module RubyInternals
    FIXNUM_FLAG = 0x1.llvm
    CHAR = Type::Int8Ty
    P_CHAR = Type::pointer(CHAR)
    LONG = MACHINE_WORD 
    INT = Type::Int32Ty
    VALUE = MACHINE_WORD
    P_VALUE = Type::pointer(VALUE)
    ID = MACHINE_WORD
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
      val_ptr = int_to_ptr(str, P_RSTRING)
      len_ptr = struct_gep(val_ptr, 1)
      load(len_ptr)
    end

    def alen(ary)
      val_ptr = int_to_ptr(ary, P_RARRAY)
      len_ptr = struct_gep(val_ptr, 1)
      load(len_ptr)
    end

    def aref(ary, idx)
      val_ptr = int_to_ptr(ary, P_RARRAY)
      data_ptr = struct_gep(val_ptr, 3)
      data_ptr = load(data_ptr)
      slot_n = gep(data_ptr, idx.llvm)
      load(slot_n)
    end

    def aset(ary, idx, set)
      val_ptr = int_to_ptr(ary, P_RARRAY)
      data_ptr = struct_gep(val_ptr, 3)
      data_ptr = load(data_ptr)
      slot_n = gep(data_ptr, idx.llvm)
      store(set, slot_n)
    end
  end
end
