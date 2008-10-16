#include "llvmruby.h"

extern "C" {
VALUE 
llvm_value_wrap(Value* v) { 
  return Data_Wrap_Struct(cLLVMValue, NULL, NULL, v); 
}

VALUE
llvm_value_get_name(VALUE self) {
  Value *v = LLVM_VAL(self);
  std::string name = v->getName();
  return rb_str_new2(name.c_str());
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
  type = ArrayType::get(type, FIX2INT(size));
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
