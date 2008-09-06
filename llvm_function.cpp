#include "llvmruby.h"
#include <sstream>

extern "C" {
VALUE 
llvm_function_wrap(Function *f) { 
  return Data_Wrap_Struct(cLLVMFunction, NULL, NULL, f); 
}

VALUE 
llvm_function_create_block(VALUE self) {
  BasicBlock *bb = BasicBlock::Create("bb", LLVM_FUNCTION(self));
  return llvm_basic_block_wrap(bb);
}

VALUE
llvm_function_arguments(VALUE self) {
  Function *f = LLVM_FUNCTION(self);
  VALUE arg_array = rb_ary_new();
  Function::arg_iterator args = f->arg_begin();
  while(args != f->arg_end()) {
    Value *arg = args++;
    rb_ary_push(arg_array, llvm_value_wrap(arg));
  }
  return arg_array;
}

VALUE
llvm_function_inspect(VALUE self) {
  Function *f = LLVM_FUNCTION(self); 
  std::ostringstream strstrm;
  strstrm << *f;
  return rb_str_new2(strstrm.str().c_str());
}
}
