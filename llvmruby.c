#include "ruby.h"

VALUE cLLVMRuby = Qnil;
VALUE cLLVMValue = Qnil;
VALUE cLLVMModule = Qnil;
VALUE cLLVMFunction = Qnil;
VALUE cLLVMBasicBlock = Qnil;
VALUE cLLVMBuilder = Qnil;
VALUE cLLVMType = Qnil;
VALUE cLLVMPointerType = Qnil;
VALUE cLLVMStructType = Qnil;
VALUE cLLVMArrayType = Qnil;
VALUE cLLVMVectorType = Qnil;
VALUE cLLVMFunctionType = Qnil;
VALUE cLLVMInstruction = Qnil;
VALUE cLLVMBinaryOps = Qnil;
VALUE cLLVMPassManager = Qnil;
VALUE cLLVMExecutionEngine = Qnil;

void init_types();
VALUE llvm_type_pointer(VALUE, VALUE);
VALUE llvm_type_struct(VALUE, VALUE, VALUE);
VALUE llvm_type_array(VALUE, VALUE, VALUE);
VALUE llvm_type_vector(VALUE, VALUE, VALUE);
VALUE llvm_type_function(VALUE, VALUE);

void init_instructions();

VALUE llvm_module_allocate(VALUE);
VALUE llvm_module_initialize(VALUE); 
VALUE llvm_module_get_or_insert_function(VALUE, VALUE);

VALUE llvm_function_allocate(VALUE);
VALUE llvm_function_create_block(VALUE);
VALUE llvm_function_arguments(VALUE);

VALUE llvm_basic_block_builder(VALUE);

VALUE llvm_builder_set_insert_point(VALUE, VALUE);
VALUE llvm_builder_bin_op(VALUE, VALUE, VALUE, VALUE);
VALUE llvm_builder_create_return(VALUE, VALUE);
VALUE llvm_builder_create_br(VALUE, VALUE);
VALUE llvm_builder_create_cond_br(VALUE, VALUE, VALUE, VALUE);

VALUE llvm_builder_create_alloca(VALUE, VALUE, VALUE);
VALUE llvm_builder_create_load(VALUE, VALUE);
VALUE llvm_builder_create_store(VALUE, VALUE, VALUE);
VALUE llvm_builder_create_icmpeq(VALUE, VALUE, VALUE);
VALUE llvm_builder_create_gep(VALUE, VALUE, VALUE);
VALUE llvm_builder_create_struct_gep(VALUE, VALUE, VALUE);
VALUE llvm_builder_create_int_to_ptr(VALUE, VALUE, VALUE);
VALUE llvm_builder_create_call(int, VALUE*, VALUE);
VALUE llvm_builder_get_global(VALUE);

VALUE llvm_value_get_constant(VALUE);
VALUE llvm_value_get_float_constant(VALUE);

VALUE llvm_pass_manager_allocate(VALUE);
VALUE llvm_pass_manager_initialize(VALUE);
VALUE llvm_pass_manager_run(VALUE, VALUE);
VALUE llvm_execution_engine_get(VALUE, VALUE);
VALUE llvm_execution_engine_run_function(VALUE, VALUE);

void Init_llvmruby() {
  cLLVMRuby = rb_define_module("LLVM");

  cLLVMType = rb_define_class_under(cLLVMRuby, "Type", rb_cObject);
  cLLVMPointerType = rb_define_class_under(cLLVMRuby, "PointerType", cLLVMType);
  cLLVMStructType = rb_define_class_under(cLLVMRuby, "StructType", cLLVMType);
  cLLVMArrayType = rb_define_class_under(cLLVMRuby, "ArrayType", cLLVMType);
  cLLVMVectorType = rb_define_class_under(cLLVMRuby, "VectorType", cLLVMType);
  cLLVMFunctionType = rb_define_class_under(cLLVMRuby, "FunctionType", cLLVMType);

  cLLVMValue = rb_define_class_under(cLLVMRuby, "Value", rb_cObject);
  cLLVMModule = rb_define_class_under(cLLVMRuby, "Module", rb_cObject);
  cLLVMFunction = rb_define_class_under(cLLVMRuby, "Function", rb_cObject);
  cLLVMBasicBlock = rb_define_class_under(cLLVMRuby, "BasicBlock", cLLVMValue);   
  cLLVMBuilder = rb_define_class_under(cLLVMRuby, "Builder", rb_cObject);

  cLLVMInstruction = rb_define_class_under(cLLVMRuby, "Instruction", rb_cObject);
  cLLVMBinaryOps = rb_define_class_under(cLLVMInstruction, "BinaryOps", rb_cObject);

  cLLVMPassManager = rb_define_class_under(cLLVMRuby, "PassManager", rb_cObject);
  cLLVMExecutionEngine = rb_define_class_under(cLLVMRuby, "ExecutionEngine", rb_cObject);

  init_types();
  rb_define_module_function(cLLVMType, "pointer", llvm_type_pointer, 1);
  rb_define_module_function(cLLVMType, "struct", llvm_type_struct, 1);
  rb_define_module_function(cLLVMType, "array", llvm_type_array, 2);
  rb_define_module_function(cLLVMType, "vector", llvm_type_vector, 2);
  rb_define_module_function(cLLVMType, "function", llvm_type_function, 2);

  rb_define_module_function(cLLVMValue, "get_constant", llvm_value_get_constant, 1);
  rb_define_module_function(cLLVMValue, "get_float_constant", llvm_value_get_float_constant, 1);

  init_instructions();

  rb_define_alloc_func(cLLVMModule, llvm_module_allocate); 
  rb_define_method(cLLVMModule, "initialize", llvm_module_initialize, 1);
  rb_define_method(cLLVMModule, "get_or_insert_function", llvm_module_get_or_insert_function, 2);

  rb_define_method(cLLVMFunction, "create_block", llvm_function_create_block, 0);
  rb_define_method(cLLVMFunction, "arguments", llvm_function_arguments, 0);

  rb_define_method(cLLVMBasicBlock, "builder", llvm_basic_block_builder, 0);

  rb_define_method(cLLVMBuilder, "set_insert_point", llvm_builder_set_insert_point, 1);
  rb_define_method(cLLVMBuilder, "bin_op", llvm_builder_bin_op, 3);
  rb_define_method(cLLVMBuilder, "create_return", llvm_builder_create_return, 1);
  rb_define_method(cLLVMBuilder, "create_br", llvm_builder_create_br, 1);
  rb_define_method(cLLVMBuilder, "create_cond_br", llvm_builder_create_cond_br, 3);
  rb_define_method(cLLVMBuilder, "create_alloca", llvm_builder_create_alloca, 2);
  rb_define_method(cLLVMBuilder, "create_load", llvm_builder_create_load, 1);
  rb_define_method(cLLVMBuilder, "create_store", llvm_builder_create_store, 2);
  rb_define_method(cLLVMBuilder, "create_icmpeq", llvm_builder_create_icmpeq, 2);
  rb_define_method(cLLVMBuilder, "create_gep", llvm_builder_create_gep, 2);
  rb_define_method(cLLVMBuilder, "create_struct_gep", llvm_builder_create_struct_gep, 2);
  rb_define_method(cLLVMBuilder, "create_int_to_ptr", llvm_builder_create_int_to_ptr, 2);
  rb_define_method(cLLVMBuilder, "create_call", llvm_builder_create_call, -1);
  rb_define_method(cLLVMBuilder, "get_global", llvm_builder_get_global, 0);

  rb_define_alloc_func(cLLVMModule, llvm_pass_manager_allocate);
  rb_define_method(cLLVMPassManager, "initialize", llvm_pass_manager_initialize, 0);
  rb_define_method(cLLVMPassManager, "run", llvm_pass_manager_run, 1);

  rb_define_module_function(cLLVMExecutionEngine, "get", llvm_execution_engine_get, 1);
  rb_define_module_function(cLLVMExecutionEngine, "run_function", llvm_execution_engine_run_function, 2);

  //printf("sizeof long: %d\n", (int)sizeof(long));
  //printf("sizeof ptr: %d\n", (int)sizeof(long*));
  //printf("sizeof value: %d\n", (int)sizeof(VALUE));
  //printf("sizeof array: %d\n", (int)sizeof(struct RArray));
  //printf("sizeof char: %d\n", (int)sizeof(char));
}
