#include "llvmruby.h"

extern "C" {
VALUE 
llvm_value_wrap(Value* v) { 
  return Data_Wrap_Struct(cLLVMValue, NULL, NULL, v); 
}

VALUE
llvm_value_name(VALUE self) {
  Value *v;
  Data_Get_Struct(self, Value, v);

  if(v->hasName()) {
    const char *name = v->getNameStart();
    int len = v->getNameLen();
    return rb_str_new(name, len);
  } else {
    return Qnil;
  }
}

VALUE
llvm_value_set_name(VALUE self, VALUE rname) {
  Value *v;
  Data_Get_Struct(self, Value, v);
  v->setName(RSTRING_PTR(rname), RSTRING_LEN(rname));
  return rname; 
}

VALUE
llvm_value_type(VALUE self) {
  Value *v;
  Data_Get_Struct(self, Value, v);
  const Type *t = v->getType();  
  return Data_Wrap_Struct(cLLVMType, NULL, NULL, (void*) t);;
}

VALUE 
llvm_value_num_uses(VALUE self) {
  Value *v;
  Data_Get_Struct(self, Value, v);
  return INT2FIX(v->getNumUses());
}

VALUE 
llvm_value_used_in_basic_block(VALUE self, VALUE rbb) {
  Value *v;
  Data_Get_Struct(self, Value, v);
  
  BasicBlock *bb;
  Data_Get_Struct(rbb, BasicBlock, bb);

  return v->isUsedInBasicBlock(bb) ? Qtrue : Qfalse;
}

VALUE 
llvm_value_replace_all_uses_with(VALUE self, VALUE rv2) {
  Value *v1, *v2;
  Data_Get_Struct(self, Value, v1);
  Data_Get_Struct(rv2, Value, v2);
  v1->replaceAllUsesWith(v2);
  return rv2;
}

VALUE 
llvm_value_get_constant(VALUE self, VALUE type, VALUE v) {
  return llvm_value_wrap(ConstantInt::get(LLVM_TYPE(type), FIX2INT(v)));
}

VALUE 
llvm_value_get_float_constant(VALUE self, VALUE v) {
  return llvm_value_wrap(ConstantFP::get(Type::FloatTy, RFLOAT(v)->value));
}

VALUE 
llvm_value_get_double_constant(VALUE self, VALUE v) {
  return llvm_value_wrap(ConstantFP::get(Type::DoubleTy, RFLOAT(v)->value));
}

VALUE
llvm_value_get_struct_constant(int argc, VALUE *argv, VALUE self) {
  StructType *t = (StructType*)DATA_PTR(argv[0]);
  std::vector<Constant*> vals;

  for(int i = 1; i < argc; ++i) {
    Constant *c = (Constant*)DATA_PTR(argv[i]);
    vals.push_back(c);
  }
  return llvm_value_wrap(ConstantStruct::get(t, vals));
}

VALUE 
llvm_value_get_immediate_constant(VALUE self, VALUE v) {
  const IntegerType* type; 
  if(sizeof(VALUE) == 4) {
    type = Type::Int32Ty;
  } else {
    type = Type::Int64Ty;
  }
  return llvm_value_wrap(ConstantInt::get(type, (long)v));
}

VALUE 
llvm_type_pointer(VALUE self, VALUE rtype) {
  Type *type;
  Data_Get_Struct(rtype, Type, type);
  Type* ptr_type = PointerType::getUnqual(type);
  return Data_Wrap_Struct(cLLVMPointerType, NULL, NULL, ptr_type);
}

VALUE 
llvm_type_struct(VALUE self, VALUE rtypes, VALUE rpacked) {
  std::vector<const Type*> types;

  for(int i = 0; i < RARRAY_LEN(rtypes); ++i) {
    VALUE v = RARRAY_PTR(rtypes)[i];
    const Type *t;
    Data_Get_Struct(v, Type, t);
    types.push_back(t);
  }
  StructType *s = StructType::get(types);
  return Data_Wrap_Struct(cLLVMStructType, NULL, NULL, s);
}

VALUE 
llvm_type_array(VALUE self, VALUE rtype, VALUE size) {
  Type *type;
  Data_Get_Struct(rtype, Type, type);
  type = ArrayType::get(type, FIX2INT(size)); 
  return Data_Wrap_Struct(cLLVMArrayType, NULL, NULL, type);
}

VALUE 
llvm_type_vector(VALUE self, VALUE rtype, VALUE size) {
  Type *type;
  Data_Get_Struct(rtype, Type, type);
  type = VectorType::get(type, FIX2INT(size));
  return Data_Wrap_Struct(cLLVMVectorType, NULL, NULL, type);
}

VALUE
llvm_type_function(int argc, VALUE *argv, VALUE self) {
  VALUE rret_type, rarg_types, var_args;

  rb_scan_args(argc, argv, "21", &rret_type, &rarg_types, &var_args);

  std::vector<const Type*> arg_types;
  for(int i = 0; i < RARRAY_LEN(rarg_types); ++i) {
    VALUE v = RARRAY_PTR(rarg_types)[i];
    arg_types.push_back(LLVM_TYPE(v));
  }
  const Type *ret_type = LLVM_TYPE(rret_type);
  FunctionType *ftype = FunctionType::get(ret_type, arg_types, RTEST(var_args));
  return Data_Wrap_Struct(cLLVMFunctionType, NULL, NULL, ftype);
}

VALUE 
llvm_type_to_s(VALUE self) {
  Type *type;
  Data_Get_Struct(self, Type, type);
  return rb_str_new2(type->getDescription().c_str());
}

VALUE 
llvm_type_type_id(VALUE self) {
  Type *type;
  Data_Get_Struct(self, Type, type);
  return INT2FIX((int) type->getTypeID());
}

void init_types() {
  rb_define_const(cLLVMType, "Int1Ty",  Data_Wrap_Struct(cLLVMType, NULL, NULL, const_cast<IntegerType*>(Type::Int1Ty)));
  rb_define_const(cLLVMType, "Int8Ty",  Data_Wrap_Struct(cLLVMType, NULL, NULL, const_cast<IntegerType*>(Type::Int8Ty)));
  rb_define_const(cLLVMType, "Int16Ty", Data_Wrap_Struct(cLLVMType, NULL, NULL, const_cast<IntegerType*>(Type::Int16Ty)));
  rb_define_const(cLLVMType, "Int32Ty", Data_Wrap_Struct(cLLVMType, NULL, NULL, const_cast<IntegerType*>(Type::Int32Ty)));
  rb_define_const(cLLVMType, "Int64Ty", Data_Wrap_Struct(cLLVMType, NULL, NULL, const_cast<IntegerType*>(Type::Int64Ty)));
  rb_define_const(cLLVMType, "VoidTy",  Data_Wrap_Struct(cLLVMType, NULL, NULL, const_cast<Type*>(Type::VoidTy)));
  rb_define_const(cLLVMType, "LabelTy",  Data_Wrap_Struct(cLLVMType, NULL, NULL, const_cast<Type*>(Type::LabelTy)));
  rb_define_const(cLLVMType, "FloatTy",  Data_Wrap_Struct(cLLVMType, NULL, NULL, const_cast<Type*>(Type::FloatTy)));
  rb_define_const(cLLVMType, "DoubleTy",  Data_Wrap_Struct(cLLVMType, NULL, NULL, const_cast<Type*>(Type::DoubleTy)));

  // Figure out details of the target machine
  const IntegerType *machine_word_type;
  if(sizeof(void*) == 4) {
    machine_word_type = Type::Int32Ty;
  } else {
    machine_word_type = Type::Int64Ty;
  }
  rb_define_const(cLLVMRuby, "MACHINE_WORD", Data_Wrap_Struct(cLLVMType, NULL, NULL, const_cast<IntegerType*>(machine_word_type)));
}
}
