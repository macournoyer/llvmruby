#include "llvmruby.h"
#include <sstream>

extern VALUE cLLVMInstruction;
extern VALUE cLLVMBinaryOps;

extern "C" {

VALUE
llvm_instruction_wrap(Instruction* i) {
   return Data_Wrap_Struct(cLLVMInstruction, NULL, NULL, i);
}

VALUE
llvm_instruction_inspect(VALUE self) {
  Instruction *i = LLVM_INSTRUCTION(self);
  std::ostringstream strstrm;
  strstrm << *i;
  return rb_str_new2(strstrm.str().c_str());
}

VALUE
llvm_instruction_get_opcode_name(VALUE self) {
  Instruction *i = LLVM_INSTRUCTION(self);
  std::string name = i->getOpcodeName();
  return rb_str_new2(name.c_str());
}


#define DEFINE_INST(type, name) rb_define_const(cLLVMInstruction, #name, INT2FIX(Instruction::name));
#define DEFINE_BINARY_INST(name) DEFINE_INST(cLLVMBinaryOps, name)
#define DEFINE_PRED(name) rb_define_const(cLLVMInstruction, #name, INT2FIX(ICmpInst::name));
#define DEFINE_FPRED(name) rb_define_const(cLLVMInstruction, #name, INT2FIX(FCmpInst::name));
void init_instructions() {
  // Standard binary operators
  DEFINE_BINARY_INST(Add)
  DEFINE_BINARY_INST(Sub)
  DEFINE_BINARY_INST(Mul)
  DEFINE_BINARY_INST(UDiv)
  DEFINE_BINARY_INST(SDiv)
  DEFINE_BINARY_INST(FDiv)
  DEFINE_BINARY_INST(URem)
  DEFINE_BINARY_INST(SRem)
  DEFINE_BINARY_INST(FRem)

  // Logical operators (integer operands)
  DEFINE_BINARY_INST(Shl) // Shift left  (logical)
  DEFINE_BINARY_INST(LShr) // Shift right (logical)
  DEFINE_BINARY_INST(AShr) // shift right (arithmetic)
  DEFINE_BINARY_INST(And)
  DEFINE_BINARY_INST(Or)
  DEFINE_BINARY_INST(Xor)

  // Integer predicates
  DEFINE_PRED(ICMP_EQ) // equal
  DEFINE_PRED(ICMP_NE) // not equal
  DEFINE_PRED(ICMP_UGT) // unsigned greater than
  DEFINE_PRED(ICMP_UGE) // unsigned greater or equal
  DEFINE_PRED(ICMP_ULT) // unsigned less than
  DEFINE_PRED(ICMP_ULE) // unsigned less or equal
  DEFINE_PRED(ICMP_SGT) // signed greater than
  DEFINE_PRED(ICMP_SGE) // signed greater or equal
  DEFINE_PRED(ICMP_SLT) // signed less than
  DEFINE_PRED(ICMP_SLE) // signed less or equal

  DEFINE_FPRED(FCMP_OEQ)
  DEFINE_FPRED(FCMP_OGT)
  DEFINE_FPRED(FCMP_OGE)
  DEFINE_FPRED(FCMP_OLT)
  DEFINE_FPRED(FCMP_OLE)
  DEFINE_FPRED(FCMP_ONE)
  DEFINE_FPRED(FCMP_ORD)
  DEFINE_FPRED(FCMP_UNO)
  DEFINE_FPRED(FCMP_UEQ)
  DEFINE_FPRED(FCMP_UGT)
  DEFINE_FPRED(FCMP_UGE)
  DEFINE_FPRED(FCMP_ULT)
  DEFINE_FPRED(FCMP_ULE)
  DEFINE_FPRED(FCMP_UNE)
}
}
