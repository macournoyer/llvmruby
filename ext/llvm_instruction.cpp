#include "llvmruby.h" 
#include <sstream>

extern VALUE cLLVMInstruction;
extern VALUE cLLVMBinaryOps;

extern "C" {

#define LAST_INSTRUCTION_NUM 100
VALUE gInstructionClasses[LAST_INSTRUCTION_NUM];

#define DATA_GET_INSTRUCTION Instruction *i; Data_Get_Struct(self, Instruction, i);

VALUE
llvm_instruction_wrap(Instruction* i) {
   return Data_Wrap_Struct(gInstructionClasses[i->getOpcode()], NULL, NULL, i);
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

VALUE 
llvm_instruction_may_read_from_memory(VALUE self) {
  DATA_GET_INSTRUCTION
  return i->mayReadFromMemory() ? Qtrue : Qfalse;
}

VALUE 
llvm_instruction_may_write_to_memory(VALUE self) {
  DATA_GET_INSTRUCTION
  return i->mayWriteToMemory() ? Qtrue : Qfalse;
}

VALUE
llvm_instruction_is_identical_to(VALUE self, VALUE ri2) {
  DATA_GET_INSTRUCTION
  CHECK_TYPE(ri2, cLLVMInstruction);
  Instruction *i2 = LLVM_INSTRUCTION(ri2);
  return i->isIdenticalTo(i2) ? Qtrue : Qfalse;
}

VALUE 
llvm_instruction_is_same_operation_as(VALUE self, VALUE ri2) {
  DATA_GET_INSTRUCTION
  CHECK_TYPE(ri2, cLLVMInstruction);
  Instruction *i2 = LLVM_INSTRUCTION(ri2);
  return i->isSameOperationAs(i2) ? Qtrue : Qfalse;
}

VALUE
llvm_instruction_is_used_outside_of_block(VALUE self, VALUE rbb) {
  DATA_GET_INSTRUCTION
  CHECK_TYPE(rbb, cLLVMBasicBlock);
  BasicBlock *bb = LLVM_BASIC_BLOCK(rbb);
  return i->isUsedOutsideOfBlock(bb) ? Qtrue: Qfalse;
}

#define DATA_GET_TERMINATOR_INST TerminatorInst *ti; Data_Get_Struct(self, TerminatorInst, ti);

VALUE
llvm_terminator_inst_num_successors(VALUE self) {
  DATA_GET_TERMINATOR_INST
  return INT2FIX(ti->getNumSuccessors());
}

VALUE
llvm_terminator_inst_get_successor(VALUE self, VALUE ridx) {
  DATA_GET_TERMINATOR_INST
  BasicBlock *bb = ti->getSuccessor(FIX2INT(ridx));
  return llvm_basic_block_wrap(bb);
}

VALUE
llvm_terminator_inst_set_successor(VALUE self, VALUE ridx, VALUE rbb) {
  DATA_GET_TERMINATOR_INST
 
  BasicBlock *bb;
  Data_Get_Struct(rbb, BasicBlock, bb);

  ti->setSuccessor(FIX2INT(ridx), bb);
  return rbb;
}

#define DATA_GET_BRANCH_INST BranchInst *bi; Data_Get_Struct(self, BranchInst, bi);

VALUE
llvm_branch_inst_is_unconditional(VALUE self) {
  DATA_GET_BRANCH_INST
  return bi->isUnconditional() ? Qtrue : Qfalse;
}

VALUE
llvm_branch_inst_is_conditional(VALUE self) {
  DATA_GET_BRANCH_INST
  return bi->isConditional() ? Qtrue : Qfalse;
}

VALUE
llvm_branch_inst_get_condition(VALUE self) {
  DATA_GET_BRANCH_INST
  return llvm_value_wrap(bi->getCondition()); 
}

VALUE
llvm_branch_inst_set_condition(VALUE self, VALUE rv) {
  DATA_GET_BRANCH_INST
  
  Value *v;
  Data_Get_Struct(rv, Value, v);

  bi->setCondition(v);
  return rv;
}

#define DATA_GET_SWITCH_INST SwitchInst *si; Data_Get_Struct(self, SwitchInst, si);

VALUE
llvm_switch_inst_get_default_dest(VALUE self) {
  DATA_GET_SWITCH_INST
  BasicBlock *bb = si->getDefaultDest();
  return llvm_basic_block_wrap(bb); 
}

VALUE
llvm_switch_inst_get_num_cases(VALUE self) {
  DATA_GET_SWITCH_INST
  return INT2FIX(si->getNumCases());
}

VALUE
llvm_switch_inst_add_case(VALUE self, VALUE rci, VALUE rbb) {
  DATA_GET_SWITCH_INST
  
  ConstantInt *ci;
  Data_Get_Struct(rci, ConstantInt, ci);

  BasicBlock *bb;
  Data_Get_Struct(rbb, BasicBlock, bb);

  si->addCase(ci, bb);
  return self;
}

#define DATA_GET_ALLOCATION_INST AllocationInst *ai; Data_Get_Struct(self, AllocationInst, ai);

VALUE 
llvm_allocation_inst_is_array_allocation(VALUE self) {
  DATA_GET_ALLOCATION_INST
  return ai->isArrayAllocation() ? true : false;
}

VALUE 
llvm_allocation_inst_array_size(VALUE self) {
  DATA_GET_ALLOCATION_INST
  return llvm_value_wrap(ai->getArraySize());
}

VALUE 
llvm_allocation_inst_allocated_type(VALUE self) {
  DATA_GET_ALLOCATION_INST
  Type *at = const_cast<Type*>(ai->getAllocatedType()); 
  return Data_Wrap_Struct(cLLVMType, NULL, NULL, at);
}

VALUE 
llvm_allocation_inst_alignment(VALUE self) {
  DATA_GET_ALLOCATION_INST
  return INT2FIX(ai->getAlignment());
}

#define DEFINE_INST(type, name) rb_define_const(cLLVMInstruction, #name, INT2FIX(Instruction::name));
#define DEFINE_BINARY_INST(name) DEFINE_INST(cLLVMBinaryOps, name)
#define DEFINE_PRED(name) rb_define_const(cLLVMInstruction, #name, INT2FIX(ICmpInst::name));
#define DEFINE_FPRED(name) rb_define_const(cLLVMInstruction, #name, INT2FIX(FCmpInst::name));
#define DEFINE_CAST(name) rb_define_const(cLLVMInstruction, #name, INT2FIX(Instruction::name));

void init_instructions() {
  for(int i = 0; i < LAST_INSTRUCTION_NUM; ++i) {
    gInstructionClasses[i] = cLLVMInstruction;
  }

  // Need to be able to quickly look up at runtime Ruby classes cooresponding to LLVM classes
  #define HANDLE_TERM_INST(Num, Opcode, Klass) gInstructionClasses[Num] = cLLVM##Klass;
  #define HANDLE_BINARY_INST(Num, Opcode, Klass) gInstructionClasses[Num] = cLLVM##Klass; 
  #include "llvm/Instruction.def"
  
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

  DEFINE_CAST(Trunc)
  DEFINE_CAST(ZExt)
  DEFINE_CAST(SExt)
  DEFINE_CAST(FPToUI)
  DEFINE_CAST(FPToSI)
  DEFINE_CAST(UIToFP)
  DEFINE_CAST(SIToFP)
  DEFINE_CAST(FPTrunc)
  DEFINE_CAST(FPExt)
  DEFINE_CAST(PtrToInt)
  DEFINE_CAST(IntToPtr)
  DEFINE_CAST(BitCast)
}
}
