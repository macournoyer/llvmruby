#include "llvmruby.h"

extern VALUE cLLVMType;
extern VALUE cLLVMPointerType;
extern VALUE cLLVMStructType;
extern VALUE cLLVMArrayType;
extern VALUE cLLVMVectorType;
extern VALUE cLLVMValue;

extern "C" {
VALUE llvm_value_wrap(Value* v) { 
  return Data_Wrap_Struct(cLLVMValue, NULL, NULL, v); 
}

VALUE llvm_value_get_constant(VALUE self, VALUE v) {
  return llvm_value_wrap(ConstantInt::get(Type::Int64Ty, FIX2INT(v)));
}

VALUE llvm_type_pointer(VALUE self, VALUE rtype) {
  Type *type;
  Data_Get_Struct(rtype, Type, type);
  Type* ptr_type = PointerType::getUnqual(type);
  return Data_Wrap_Struct(cLLVMPointerType, NULL, NULL, ptr_type);
}

VALUE llvm_type_struct(VALUE self, VALUE rtypes, VALUE rpacked) {
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

VALUE llvm_type_array(VALUE self, VALUE rtype, VALUE size) {
  Type *type;
  Data_Get_Struct(rtype, Type, type);
  type = ArrayType::get(type, FIX2INT(size)); 
  return Data_Wrap_Struct(cLLVMArrayType, NULL, NULL, type);
}

VALUE llvm_type_vector(VALUE self, VALUE rtype, VALUE size) {
  Type *type;
  Data_Get_Struct(rtype, Type, type);
  type = ArrayType::get(type, FIX2INT(size));
  return Data_Wrap_Struct(cLLVMVectorType, NULL, NULL, type);
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
}
}
