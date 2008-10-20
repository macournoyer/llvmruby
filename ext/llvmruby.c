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
VALUE cLLVMTerminatorInst = Qnil;
VALUE cLLVMUnaryInstruction = Qnil;
VALUE cLLVMBinaryOperator = Qnil;
VALUE cLLVMCmpInst = Qnil;
VALUE cLLVMICmpInst = Qnil;
VALUE cLLVMFCmpInst = Qnil;
VALUE cLLVMAllocationInst = Qnil;
VALUE cLLVMFreeInst = Qnil;
VALUE cLLVMPhi = Qnil;
VALUE cLLVMBinaryOps = Qnil;
VALUE cLLVMPassManager = Qnil;
VALUE cLLVMExecutionEngine = Qnil;

#define HANDLE_TERM_INST(Num, Opcode, Klass) VALUE cLLVM##Klass;
#define HANDLE_MEMORY_INST(Num, Opcode, Klass) VALUE cLLVM##Klass;
#include "llvm/Instruction.def"

void init_types();
VALUE llvm_type_pointer(VALUE, VALUE);
VALUE llvm_type_struct(VALUE, VALUE, VALUE);
VALUE llvm_type_array(VALUE, VALUE, VALUE);
VALUE llvm_type_vector(VALUE, VALUE, VALUE);
VALUE llvm_type_function2(VALUE, VALUE);
VALUE llvm_type_function(VALUE, VALUE, VALUE);

void init_instructions();

VALUE llvm_module_allocate(VALUE);
VALUE llvm_module_initialize(VALUE); 
VALUE llvm_module_get_or_insert_function(VALUE, VALUE);
VALUE llvm_module_get_function(VALUE, VALUE);
VALUE llvm_module_global_variable(VALUE, VALUE, VALUE);
VALUE llvm_module_external_function(VALUE, VALUE, VALUE);
VALUE llvm_module_read_assembly(VALUE, VALUE);
VALUE llvm_module_read_bitcode(VALUE, VALUE);
VALUE llvm_module_write_bitcode(VALUE, VALUE);
VALUE llvm_module_inspect(VALUE);

VALUE llvm_function_allocate(VALUE);
VALUE llvm_function_create_block(VALUE);
VALUE llvm_function_arguments(VALUE);
VALUE llvm_function_inspect(VALUE);
VALUE llvm_function_get_basic_block_list(VALUE);

VALUE llvm_basic_block_builder(VALUE);
VALUE llvm_basic_block_size(VALUE);
VALUE llvm_basic_block_get_instruction_list(VALUE);

VALUE llvm_instruction_inspect(VALUE);
VALUE llvm_instruction_get_opcode_name(VALUE);
VALUE llvm_instruction_may_read_from_memory(VALUE);
VALUE llvm_instruction_may_write_to_memory(VALUE);
VALUE llvm_instruction_is_identical_to(VALUE, VALUE);
VALUE llvm_instruction_is_same_operation_as(VALUE, VALUE);
VALUE llvm_instruction_is_used_outside_of_block(VALUE, VALUE);

VALUE llvm_terminator_inst_num_successors(VALUE);
VALUE llvm_terminator_inst_get_successor(VALUE, VALUE);
VALUE llvm_terminator_inst_set_successor(VALUE, VALUE, VALUE);

VALUE llvm_branch_inst_is_conditional(VALUE);
VALUE llvm_branch_inst_is_unconditional(VALUE);
VALUE llvm_branch_inst_get_condition(VALUE);
VALUE llvm_branch_inst_set_condition(VALUE, VALUE);

VALUE llvm_switch_inst_get_default_dest(VALUE);
VALUE llvm_switch_inst_get_num_cases(VALUE);
VALUE llvm_switch_inst_add_case(VALUE, VALUE, VALUE);

VALUE llvm_allocation_inst_is_array_allocation(VALUE);
VALUE llvm_allocation_inst_array_size(VALUE);
VALUE llvm_allocation_inst_allocated_type(VALUE);
VALUE llvm_allocation_inst_alignment(VALUE);

VALUE llvm_builder_set_insert_point(VALUE, VALUE);
VALUE llvm_builder_bin_op(VALUE, VALUE, VALUE, VALUE);
VALUE llvm_builder_phi(VALUE, VALUE);
VALUE llvm_builder_return(VALUE, VALUE);
VALUE llvm_builder_br(VALUE, VALUE);
VALUE llvm_builder_cond_br(VALUE, VALUE, VALUE, VALUE);
VALUE llvm_builder_switch(VALUE, VALUE, VALUE);

VALUE llvm_builder_malloc(VALUE, VALUE, VALUE);
VALUE llvm_builder_free(VALUE, VALUE);
VALUE llvm_builder_alloca(VALUE, VALUE, VALUE);
VALUE llvm_builder_load(VALUE, VALUE);
VALUE llvm_builder_store(VALUE, VALUE, VALUE);
VALUE llvm_builder_icmp(VALUE, VALUE, VALUE, VALUE);
VALUE llvm_builder_fcmp(VALUE, VALUE, VALUE, VALUE);
VALUE llvm_builder_gep(VALUE, VALUE, VALUE);
VALUE llvm_builder_struct_gep(VALUE, VALUE, VALUE);
VALUE llvm_builder_cast(VALUE, VALUE, VALUE, VALUE);
VALUE llvm_builder_int_to_ptr(VALUE, VALUE, VALUE);
VALUE llvm_builder_int_cast(VALUE, VALUE, VALUE);
VALUE llvm_builder_call(int, VALUE*, VALUE);
VALUE llvm_builder_insert_element(VALUE, VALUE, VALUE, VALUE);
VALUE llvm_builder_extract_element(VALUE, VALUE, VALUE);
VALUE llvm_builder_get_global(VALUE);
VALUE llvm_builder_create_global_string_ptr(VALUE);

VALUE llvm_value_get_constant(VALUE);
VALUE llvm_value_get_float_constant(VALUE);
VALUE llvm_value_get_double_constant(VALUE);
VALUE llvm_value_get_immediate_constant(VALUE);
VALUE llvm_value_get_struct_constant(int, VALUE*, VALUE);
VALUE llvm_value_name(VALUE);
VALUE llvm_value_set_name(VALUE, VALUE);
VALUE llvm_value_num_uses(VALUE);
VALUE llvm_value_used_in_basic_block(VALUE, VALUE);
VALUE llvm_value_replace_all_uses_with(VALUE, VALUE);

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

  cLLVMInstruction = rb_define_class_under(cLLVMRuby, "Instruction", cLLVMValue);
  cLLVMUnaryInstruction = rb_define_class_under(cLLVMRuby, "UnaryInstruction", cLLVMInstruction);
  cLLVMBinaryOperator = rb_define_class_under(cLLVMRuby, "BinaryOperator", cLLVMInstruction);
  cLLVMTerminatorInst = rb_define_class_under(cLLVMRuby, "TerminatorInst", cLLVMInstruction);
  cLLVMAllocationInst = rb_define_class_under(cLLVMRuby, "AllocationInst", cLLVMInstruction);
  cLLVMBinaryOps = rb_define_class_under(cLLVMInstruction, "BinaryOps", rb_cObject);

  #define HANDLE_TERM_INST(Num, Opcode, Klass) cLLVM##Klass = rb_define_class_under(cLLVMRuby, #Klass, cLLVMTerminatorInst);
  #include "llvm/Instruction.def"

  cLLVMLoadInst = rb_define_class_under(cLLVMRuby, "LoadInst", cLLVMUnaryInstruction);
  cLLVMStoreInst = rb_define_class_under(cLLVMRuby, "StoreInst", cLLVMInstruction);
  cLLVMFreeInst = rb_define_class_under(cLLVMRuby, "FreeInst", cLLVMUnaryInstruction);
  cLLVMGetElementPtrInst = rb_define_class_under(cLLVMRuby, "GetElementPtrInst", cLLVMInstruction);
  cLLVMAllocaInst = rb_define_class_under(cLLVMRuby, "AllocaInst", cLLVMAllocationInst);
  cLLVMMallocInst = rb_define_class_under(cLLVMRuby, "MallocInst", cLLVMAllocationInst);

  cLLVMCmpInst = rb_define_class_under(cLLVMRuby, "CmpInst", cLLVMInstruction);
  cLLVMICmpInst = rb_define_class_under(cLLVMRuby, "ICmpInst", cLLVMCmpInst);
  cLLVMFCmpInst = rb_define_class_under(cLLVMRuby, "FCmpInst", cLLVMCmpInst);
  cLLVMPhi = rb_define_class_under(cLLVMRuby, "Phi", cLLVMValue);

  cLLVMPassManager = rb_define_class_under(cLLVMRuby, "PassManager", rb_cObject);
  cLLVMExecutionEngine = rb_define_class_under(cLLVMRuby, "ExecutionEngine", rb_cObject);

  init_types();
  rb_define_module_function(cLLVMType, "pointer", llvm_type_pointer, 1);
  rb_define_module_function(cLLVMType, "struct", llvm_type_struct, 1);
  rb_define_module_function(cLLVMType, "array", llvm_type_array, 2);
  rb_define_module_function(cLLVMType, "vector", llvm_type_vector, 2);
  rb_define_module_function(cLLVMType, "function", llvm_type_function, -1);

  rb_define_module_function(cLLVMValue, "get_constant", llvm_value_get_constant, 2);
  rb_define_module_function(cLLVMValue, "get_float_constant", llvm_value_get_float_constant, 1);
  rb_define_module_function(cLLVMValue, "get_double_constant", llvm_value_get_double_constant, 1);
  rb_define_module_function(cLLVMValue, "get_immediate_constant", llvm_value_get_immediate_constant, 1);
  rb_define_module_function(cLLVMValue, "get_struct_constant", llvm_value_get_struct_constant, -1);
  rb_define_method(cLLVMValue, "name", llvm_value_name, 0);
  rb_define_method(cLLVMValue, "name=", llvm_value_set_name, 1);
  rb_define_method(cLLVMValue, "num_uses", llvm_value_num_uses, 0);
  rb_define_method(cLLVMValue, "used_in_basic_block?", llvm_value_used_in_basic_block, 1);
  rb_define_method(cLLVMValue, "replace_all_uses_with", llvm_value_replace_all_uses_with, 1);

  init_instructions();

  rb_define_alloc_func(cLLVMModule, llvm_module_allocate);
  rb_define_module_function(cLLVMModule, "read_assembly", llvm_module_read_assembly, 1);
  rb_define_module_function(cLLVMModule, "read_bitcode", llvm_module_read_bitcode, 1);
  rb_define_method(cLLVMModule, "initialize", llvm_module_initialize, 1);
  rb_define_method(cLLVMModule, "get_or_insert_function", llvm_module_get_or_insert_function, 2);
  rb_define_method(cLLVMModule, "get_function", llvm_module_get_function, 1);
  rb_define_method(cLLVMModule, "global_variable", llvm_module_global_variable, 2);
  rb_define_method(cLLVMModule, "external_function", llvm_module_external_function, 2);
  rb_define_method(cLLVMModule, "write_bitcode", llvm_module_write_bitcode, 1);
  rb_define_method(cLLVMModule, "inspect", llvm_module_inspect, 0);

  rb_define_method(cLLVMFunction, "create_block", llvm_function_create_block, 0);
  rb_define_method(cLLVMFunction, "arguments", llvm_function_arguments, 0);
  rb_define_method(cLLVMFunction, "inspect", llvm_function_inspect, 0);
  rb_define_method(cLLVMFunction, "get_basic_block_list", llvm_function_get_basic_block_list, 0);

  rb_define_method(cLLVMBasicBlock, "builder", llvm_basic_block_builder, 0);
  rb_define_method(cLLVMBasicBlock, "size", llvm_basic_block_size, 0);
  rb_define_method(cLLVMBasicBlock, "get_instruction_list", llvm_basic_block_get_instruction_list, 0);

  rb_define_method(cLLVMInstruction, "inspect", llvm_instruction_inspect, 0);
  rb_define_method(cLLVMInstruction, "get_opcode_name", llvm_instruction_get_opcode_name, 0);
  rb_define_method(cLLVMInstruction, "may_read_from_memory?", llvm_instruction_may_read_from_memory, 0);
  rb_define_method(cLLVMInstruction, "may_write_to_memory?", llvm_instruction_may_write_to_memory, 0);
  rb_define_method(cLLVMInstruction, "identical_to?", llvm_instruction_is_identical_to, 1);
  rb_define_method(cLLVMInstruction, "same_operation_as?", llvm_instruction_is_same_operation_as, 1);
  rb_define_method(cLLVMInstruction, "used_outside_of_block?", llvm_instruction_is_used_outside_of_block, 1);
  
  rb_define_method(cLLVMTerminatorInst, "num_successors", llvm_terminator_inst_num_successors, 0);
  rb_define_method(cLLVMTerminatorInst, "get_successor", llvm_terminator_inst_get_successor, 1);
  rb_define_method(cLLVMTerminatorInst, "set_successor", llvm_terminator_inst_set_successor, 2);

  rb_define_method(cLLVMBranchInst, "conditional?", llvm_branch_inst_is_conditional, 0);
  rb_define_method(cLLVMBranchInst, "unconditional?", llvm_branch_inst_is_unconditional, 0);
  rb_define_method(cLLVMBranchInst, "condition", llvm_branch_inst_get_condition, 0);
  rb_define_method(cLLVMBranchInst, "condition=", llvm_branch_inst_set_condition, 1);

  rb_define_method(cLLVMSwitchInst, "get_default_dest", llvm_switch_inst_get_default_dest, 0);
  rb_define_method(cLLVMSwitchInst, "get_num_cases", llvm_switch_inst_get_num_cases, 0);
  rb_define_method(cLLVMSwitchInst, "add_case", llvm_switch_inst_add_case, 2);

  rb_define_method(cLLVMAllocationInst, "array_allocation?", llvm_allocation_inst_is_array_allocation, 0);
  rb_define_method(cLLVMAllocationInst, "array_size", llvm_allocation_inst_array_size, 0);
  rb_define_method(cLLVMAllocationInst, "allocated_type", llvm_allocation_inst_allocated_type, 0);
  rb_define_method(cLLVMAllocationInst, "alignment", llvm_allocation_inst_alignment, 0);

  rb_define_method(cLLVMBuilder, "set_insert_point", llvm_builder_set_insert_point, 1);
  rb_define_method(cLLVMBuilder, "bin_op", llvm_builder_bin_op, 3);
  rb_define_method(cLLVMBuilder, "phi", llvm_builder_phi, 1);
  rb_define_method(cLLVMBuilder, "return", llvm_builder_return, 1);
  rb_define_method(cLLVMBuilder, "br", llvm_builder_br, 1);
  rb_define_method(cLLVMBuilder, "cond_br", llvm_builder_cond_br, 3);
  rb_define_method(cLLVMBuilder, "switch", llvm_builder_switch, 2);
  rb_define_method(cLLVMBuilder, "malloc", llvm_builder_malloc, 2);
  rb_define_method(cLLVMBuilder, "free", llvm_builder_free, 1);
  rb_define_method(cLLVMBuilder, "alloca", llvm_builder_alloca, 2);
  rb_define_method(cLLVMBuilder, "load", llvm_builder_load, 1);
  rb_define_method(cLLVMBuilder, "store", llvm_builder_store, 2);
  rb_define_method(cLLVMBuilder, "icmp", llvm_builder_icmp, 3);
  rb_define_method(cLLVMBuilder, "fcmp", llvm_builder_fcmp, 3);

  rb_define_method(cLLVMBuilder, "gep", llvm_builder_gep, 2);
  rb_define_method(cLLVMBuilder, "struct_gep", llvm_builder_struct_gep, 2);
  rb_define_method(cLLVMBuilder, "cast", llvm_builder_cast, 3);
  rb_define_method(cLLVMBuilder, "int_to_ptr", llvm_builder_int_to_ptr, 2);
  rb_define_method(cLLVMBuilder, "int_cast", llvm_builder_int_cast, 3);
  rb_define_method(cLLVMBuilder, "call", llvm_builder_call, -1);
  rb_define_method(cLLVMBuilder, "insert_element", llvm_builder_insert_element, 3);
  rb_define_method(cLLVMBuilder, "extract_element", llvm_builder_extract_element, 2);
  rb_define_method(cLLVMBuilder, "get_global", llvm_builder_get_global, 0);
  rb_define_method(cLLVMBuilder, "create_global_string_ptr", llvm_builder_create_global_string_ptr, 1);

  rb_define_method(cLLVMPhi, "add_incoming", llvm_phi_add_incoming, 2);

  rb_define_alloc_func(cLLVMModule, llvm_pass_manager_allocate);
  rb_define_method(cLLVMPassManager, "initialize", llvm_pass_manager_initialize, 0);
  rb_define_method(cLLVMPassManager, "run", llvm_pass_manager_run, 1);

  rb_define_module_function(cLLVMExecutionEngine, "get", llvm_execution_engine_get, 1);
  rb_define_module_function(cLLVMExecutionEngine, "run_function", llvm_execution_engine_run_function, -1);
  rb_define_module_function(cLLVMExecutionEngine, "run_autoconvert", llvm_execution_engine_run_autoconvert, 1);

  /*
  printf("sizeof long: %d\n", (int)sizeof(long));
  printf("sizeof ptr: %d\n", (int)sizeof(long*));
  printf("sizeof value: %d\n", (int)sizeof(VALUE));
  printf("sizeof array: %d\n", (int)sizeof(struct RArray));
  printf("sizeof int: %d\n", (int)sizeof(int));
  printf("sizeof char: %d\n", (int)sizeof(char));
  */
}
