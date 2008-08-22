#include "llvmruby.h"

extern VALUE cLLVMBasicBlock;
extern VALUE cLLVMBuilder;

extern "C" {
VALUE 
llvm_basic_block_wrap(BasicBlock* bb) { 
  return Data_Wrap_Struct(cLLVMBasicBlock, NULL, NULL, bb); 
}

VALUE 
llvm_basic_block_builder(VALUE self) {
  BasicBlock* bb;
  Data_Get_Struct(self, BasicBlock, bb);
  IRBuilder<> *builder = new IRBuilder<>(bb);
  return Data_Wrap_Struct(cLLVMBuilder, NULL, NULL, builder);
}

#define DATA_GET_BUILDER IRBuilder<>* builder; Data_Get_Struct(self, IRBuilder<>, builder);

VALUE 
llvm_builder_bin_op(VALUE self, VALUE rbin_op, VALUE rv1, VALUE rv2) {
  DATA_GET_BUILDER

  Instruction::BinaryOps bin_op = (Instruction::BinaryOps)FIX2INT(rbin_op);
  
  Value *v1, *v2; 
  Data_Get_Struct(rv1, Value, v1);
  Data_Get_Struct(rv2, Value, v2);
  Value *res = builder->CreateBinOp(bin_op, v1, v2);
  return llvm_value_wrap(res);
}

VALUE llvm_builder_create_add(VALUE self, VALUE rv1, VALUE rv2) {
  IRBuilder<>* builder;
  Data_Get_Struct(self, IRBuilder<>, builder);

  Value *v1, *v2;
  Data_Get_Struct(rv1, Value, v1);
  Data_Get_Struct(rv2, Value, v2);

  Value *res = builder->CreateBinOp(Instruction::Add, v1, v2);
  return llvm_value_wrap(res);
}

VALUE llvm_builder_create_sub(VALUE self, VALUE rv1, VALUE rv2) {
  IRBuilder<>* builder;
  Data_Get_Struct(self, IRBuilder<>, builder);

  Value *v1, *v2;
  Data_Get_Struct(rv1, Value, v1);
  Data_Get_Struct(rv2, Value, v2);

  Value *res = builder->CreateBinOp(Instruction::Sub, v1, v2);
  return llvm_value_wrap(res);
}

VALUE llvm_builder_create_mul(VALUE self, VALUE rv1, VALUE rv2) {
  IRBuilder<>* builder;
  Data_Get_Struct(self, IRBuilder<>, builder);

  Value *v1, *v2;
  Data_Get_Struct(rv1, Value, v1);
  Data_Get_Struct(rv2, Value, v2);

  Value *res = builder->CreateBinOp(Instruction::Mul, v1, v2);
  return llvm_value_wrap(res);
}

VALUE llvm_builder_create_xor(VALUE self, VALUE rv1, VALUE rv2) {
  IRBuilder<>* builder;
  Data_Get_Struct(self, IRBuilder<>, builder);

  Value *v1, *v2;
  Data_Get_Struct(rv1, Value, v1);
  Data_Get_Struct(rv2, Value, v2);

  Value *res = builder->CreateBinOp(Instruction::Xor, v1, v2);
  return llvm_value_wrap(res);
}

VALUE llvm_builder_create_and(VALUE self, VALUE rv1, VALUE rv2) {
  IRBuilder<>* builder;
  Data_Get_Struct(self, IRBuilder<>, builder);

  Value *v1, *v2;
  Data_Get_Struct(rv1, Value, v1);
  Data_Get_Struct(rv2, Value, v2);

  Value *res = builder->CreateBinOp(Instruction::And, v1, v2);
  return llvm_value_wrap(res);
}

VALUE llvm_builder_create_shl(VALUE self, VALUE rv1, VALUE rv2) {
  IRBuilder<>* builder;
  Data_Get_Struct(self, IRBuilder<>, builder);

  Value *v1, *v2;
  Data_Get_Struct(rv1, Value, v1);
  Data_Get_Struct(rv2, Value, v2);

  Value *res = builder->CreateBinOp(Instruction::Shl, v1, v2);
  return llvm_value_wrap(res);
}

VALUE llvm_builder_create_lshr(VALUE self, VALUE rv1, VALUE rv2) {
  IRBuilder<>* builder;
  Data_Get_Struct(self, IRBuilder<>, builder);

  Value *v1, *v2;
  Data_Get_Struct(rv1, Value, v1);
  Data_Get_Struct(rv2, Value, v2);

  Value *res = builder->CreateBinOp(Instruction::LShr, v1, v2);
  return llvm_value_wrap(res);
}

VALUE llvm_builder_create_return(VALUE self, VALUE rv) {
  IRBuilder<>* builder;
  Data_Get_Struct(self, IRBuilder<>, builder);

  Value *v;
  Data_Get_Struct(rv, Value, v);
  return llvm_value_wrap(builder->CreateRet(v));
}

VALUE llvm_builder_create_br(VALUE self, VALUE rblock) {
  IRBuilder<>* builder;
  Data_Get_Struct(self, IRBuilder<>, builder);

  BasicBlock *bb;
  Data_Get_Struct(rblock, BasicBlock, bb);
  return llvm_value_wrap(builder->CreateBr(bb)); 
}  

VALUE llvm_builder_create_cond_br(VALUE self, VALUE rcond, VALUE rtrue_block, VALUE rfalse_block) {
  IRBuilder<>* builder;
  Data_Get_Struct(self, IRBuilder<>, builder);

  Value *cond;
  Data_Get_Struct(rcond, Value, cond);

  BasicBlock *true_block, *false_block;
  Data_Get_Struct(rtrue_block, BasicBlock, true_block);
  Data_Get_Struct(rfalse_block, BasicBlock, false_block);

  return llvm_value_wrap(builder->CreateCondBr(cond, true_block, false_block));
}
  
VALUE llvm_builder_create_alloca(VALUE self, VALUE rtype, VALUE rsize) {
  IRBuilder<>* builder;
  Data_Get_Struct(self, IRBuilder<>, builder);

  const Type* type;
  Data_Get_Struct(rtype, Type, type);

  Value *size = ConstantInt::get(Type::Int32Ty, FIX2INT(rsize));
  Value *v = builder->CreateAlloca(type, size);
  return llvm_value_wrap(v);
}

VALUE llvm_builder_create_load(VALUE self, VALUE rptr) {
  IRBuilder<>* builder;
  Data_Get_Struct(self, IRBuilder<>, builder);

  Value *ptr;
  Data_Get_Struct(rptr, Value, ptr);
  return llvm_value_wrap(builder->CreateLoad(ptr));
}

VALUE llvm_builder_create_store(VALUE self, VALUE rv, VALUE rptr) {
  IRBuilder<>* builder;
  Data_Get_Struct(self, IRBuilder<>, builder);

  Value *v, *ptr;
  Data_Get_Struct(rv, Value, v);
  Data_Get_Struct(rptr, Value, ptr);
  return llvm_value_wrap(builder->CreateStore(v, ptr));
}

VALUE llvm_builder_create_icmpeq(VALUE self, VALUE rlhs, VALUE rrhs) {
  IRBuilder<>* builder; 
  Data_Get_Struct(self, IRBuilder<>, builder);

  Value *lhs, *rhs;
  Data_Get_Struct(rlhs, Value, lhs);
  Data_Get_Struct(rrhs, Value, rhs);
  return llvm_value_wrap(builder->CreateICmpEQ(lhs, rhs));
}

VALUE llvm_builder_create_gep(VALUE self, VALUE rptr, VALUE ridx) {
  IRBuilder<>* builder; 
  Data_Get_Struct(self, IRBuilder<>, builder);

  Value *ptr, *idx;
  Data_Get_Struct(rptr, Value, ptr);
  Data_Get_Struct(ridx, Value, idx);
  return llvm_value_wrap(builder->CreateGEP(ptr, idx));
}

VALUE llvm_builder_create_struct_gep(VALUE self, VALUE rptr, VALUE ridx) {
  IRBuilder<>* builder;
  Data_Get_Struct(self, IRBuilder<>, builder);

  Value *ptr;
  Data_Get_Struct(rptr, Value, ptr);
  return llvm_value_wrap(builder->CreateStructGEP(ptr, FIX2INT(ridx)));
}

VALUE llvm_builder_create_int_to_ptr(VALUE self, VALUE ri, VALUE rtype) {
  IRBuilder<>* builder;
  Data_Get_Struct(self, IRBuilder<>, builder);

  Value *i;
  Data_Get_Struct(ri, Value, i);
 
  const Type* type; 
  Data_Get_Struct(rtype, Type, type);

  return llvm_value_wrap(builder->CreateIntToPtr(i, type));
}
}
