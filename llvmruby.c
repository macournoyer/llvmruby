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
VALUE cLLVMPhi = Qnil;
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
VALUE llvm_module_external_function(VALUE, VALUE, VALUE);
VALUE llvm_module_write_bitcode(VALUE, VALUE);

VALUE llvm_function_allocate(VALUE);
VALUE llvm_function_create_block(VALUE);
VALUE llvm_function_arguments(VALUE);

VALUE llvm_basic_block_builder(VALUE);

VALUE llvm_builder_set_insert_point(VALUE, VALUE);
VALUE llvm_builder_bin_op(VALUE, VALUE, VALUE, VALUE);
VALUE llvm_builder_phi(VALUE, VALUE);
VALUE llvm_builder_return(VALUE, VALUE);
VALUE llvm_builder_br(VALUE, VALUE);
VALUE llvm_builder_cond_br(VALUE, VALUE, VALUE, VALUE);

VALUE llvm_builder_alloca(VALUE, VALUE, VALUE);
VALUE llvm_builder_load(VALUE, VALUE);
VALUE llvm_builder_store(VALUE, VALUE, VALUE);
VALUE llvm_builder_icmp(VALUE, VALUE, VALUE, VALUE);
VALUE llvm_builder_gep(VALUE, VALUE, VALUE);
VALUE llvm_builder_struct_gep(VALUE, VALUE, VALUE);
VALUE llvm_builder_int_to_ptr(VALUE, VALUE, VALUE);
VALUE llvm_builder_int_cast(VALUE, VALUE, VALUE);
VALUE llvm_builder_call(int, VALUE*, VALUE);
VALUE llvm_builder_get_global(VALUE);

VALUE llvm_value_get_constant(VALUE);
VALUE llvm_value_get_float_constant(VALUE);

VALUE llvm_phi_add_incoming(VALUE, VALUE, VALUE);

VALUE llvm_pass_manager_allocate(VALUE);
VALUE llvm_pass_manager_initialize(VALUE);
VALUE llvm_pass_manager_run(VALUE, VALUE);
VALUE llvm_execution_engine_get(VALUE, VALUE);
VALUE llvm_execution_engine_run_function(int, VALUE*, VALUE);
VALUE llvm_execution_engine_run_autoconvert(VALUE, VALUE);

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
  cLLVMPhi = rb_define_class_under(cLLVMRuby, "Phi", cLLVMValue);

  cLLVMPassManager = rb_define_class_under(cLLVMRuby, "PassManager", rb_cObject);
  cLLVMExecutionEngine = rb_define_class_under(cLLVMRuby, "ExecutionEngine", rb_cObject);

  init_types();
  rb_define_module_function(cLLVMType, "pointer", llvm_type_pointer, 1);
  rb_define_module_function(cLLVMType, "struct", llvm_type_struct, 1);
  rb_define_module_function(cLLVMType, "array", llvm_type_array, 2);
  rb_define_module_function(cLLVMType, "vector", llvm_type_vector, 2);
  rb_define_module_function(cLLVMType, "function", llvm_type_function, 2);

  rb_define_module_function(cLLVMValue, "get_constant", llvm_value_get_constant, 2);
  rb_define_module_function(cLLVMValue, "get_float_constant", llvm_value_get_float_constant, 1);

  init_instructions();

  rb_define_alloc_func(cLLVMModule, llvm_module_allocate); 
  rb_define_method(cLLVMModule, "initialize", llvm_module_initialize, 1);
  rb_define_method(cLLVMModule, "get_or_insert_function", llvm_module_get_or_insert_function, 2);
  rb_define_method(cLLVMModule, "external_function", llvm_module_external_function, 2);
  rb_define_method(cLLVMModule, "write_bitcode", llvm_module_write_bitcode, 1);

  rb_define_method(cLLVMFunction, "create_block", llvm_function_create_block, 0);
  rb_define_method(cLLVMFunction, "arguments", llvm_function_arguments, 0);

  rb_define_method(cLLVMBasicBlock, "builder", llvm_basic_block_builder, 0);

  rb_define_method(cLLVMBuilder, "set_insert_point", llvm_builder_set_insert_point, 1);
  rb_define_method(cLLVMBuilder, "bin_op", llvm_builder_bin_op, 3);
  rb_define_method(cLLVMBuilder, "phi", llvm_builder_phi, 1);
  rb_define_method(cLLVMBuilder, "return", llvm_builder_return, 1);
  rb_define_method(cLLVMBuilder, "br", llvm_builder_br, 1);
  rb_define_method(cLLVMBuilder, "cond_br", llvm_builder_cond_br, 3);
  rb_define_method(cLLVMBuilder, "alloca", llvm_builder_alloca, 2);
  rb_define_method(cLLVMBuilder, "load", llvm_builder_load, 1);
  rb_define_method(cLLVMBuilder, "store", llvm_builder_store, 2);
  rb_define_method(cLLVMBuilder, "icmp", llvm_builder_icmp, 3);

  rb_define_method(cLLVMBuilder, "gep", llvm_builder_gep, 2);
  rb_define_method(cLLVMBuilder, "struct_gep", llvm_builder_struct_gep, 2);
  rb_define_method(cLLVMBuilder, "int_to_ptr", llvm_builder_int_to_ptr, 2);
  rb_define_method(cLLVMBuilder, "int_cast", llvm_builder_int_cast, 3);
  rb_define_method(cLLVMBuilder, "call", llvm_builder_call, -1);
  rb_define_method(cLLVMBuilder, "get_global", llvm_builder_get_global, 0);

  rb_define_method(cLLVMPhi, "add_incoming", llvm_phi_add_incoming, 2);

  rb_define_alloc_func(cLLVMModule, llvm_pass_manager_allocate);
  rb_define_method(cLLVMPassManager, "initialize", llvm_pass_manager_initialize, 0);
  rb_define_method(cLLVMPassManager, "run", llvm_pass_manager_run, 1);

  rb_define_module_function(cLLVMExecutionEngine, "get", llvm_execution_engine_get, 1);
  rb_define_module_function(cLLVMExecutionEngine, "run_function", llvm_execution_engine_run_function, -1);
  rb_define_module_function(cLLVMExecutionEngine, "run_autoconvert", llvm_execution_engine_run_autoconvert, 1);

  //printf("sizeof long: %d\n", (int)sizeof(long));
  //printf("sizeof ptr: %d\n", (int)sizeof(long*));
  //printf("sizeof value: %d\n", (int)sizeof(VALUE));
  //printf("sizeof array: %d\n", (int)sizeof(struct RArray));
  //printf("sizeof char: %d\n", (int)sizeof(char));
}
