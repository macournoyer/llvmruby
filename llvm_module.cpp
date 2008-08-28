#include "llvmruby.h"
#include "llvm/Bitcode/ReaderWriter.h"
#include <fstream>

extern "C" {

VALUE
llvm_module_allocate(VALUE klass) {
  return Data_Wrap_Struct(klass, NULL, NULL, NULL);
}

VALUE
llvm_module_initialize(VALUE self, VALUE rname) {
  Check_Type(rname, T_STRING);
  DATA_PTR(self) = new Module(StringValuePtr(rname));
  return self;
}

VALUE
llvm_module_get_or_insert_function(VALUE self, VALUE name, VALUE rtype) {
  Check_Type(name, T_STRING);
  CHECK_TYPE(rtype, cLLVMFunctionType);

  Module *m = LLVM_MODULE(self);
  FunctionType *type = LLVM_FUNC_TYPE(rtype);
  Function *f = cast<Function>(m->getOrInsertFunction(StringValuePtr(name), type));
  return llvm_function_wrap(f); 
}


VALUE
llvm_pass_manager_allocate(VALUE klass) {
  return Data_Wrap_Struct(klass, NULL, NULL, NULL);
}

VALUE
llvm_pass_manager_initialize(VALUE self) {
  PassManager *pm = new PassManager;
  DATA_PTR(self) = pm;
/*
  p.add(new TargetData(data->M));
  p.add(createVerifierPass());
  p.add(createLowerSetJmpPass());
  p.add(createRaiseAllocationsPass());
  p.add(createCFGSimplificationPass());
  p.add(createPromoteMemoryToRegisterPass());
  p.add(createGlobalOptimizerPass());
  p.add(createGlobalDCEPass());
  p.add(createFunctionInliningPass());
  p.run(*data->M);
*/
  return self;
}

VALUE
llvm_pass_manager_run(VALUE self, VALUE module) {
  ((PassManager*)DATA_PTR(self))->run(*LLVM_MODULE(module));
  return Qtrue;
}

static ExecutionEngine *EE = NULL;

VALUE
llvm_execution_engine_get(VALUE klass, VALUE module) {
  CHECK_TYPE(module, cLLVMModule);

  Module *m = LLVM_MODULE(module);
  ExistingModuleProvider *MP = new ExistingModuleProvider(m);

  if(EE == NULL) {
    EE = ExecutionEngine::create(MP, false);
  } else {
    EE->addModuleProvider(MP);
  }

  return Qtrue;
}

VALUE
llvm_module_external_function(VALUE self, VALUE name, VALUE type) {
  Check_Type(name, T_STRING);
  CHECK_TYPE(type, cLLVMFunctionType);

  Module *module = LLVM_MODULE(self);
  Function *f = Function::Create(
    LLVM_FUNC_TYPE(type), 
    Function::ExternalLinkage, 
    StringValuePtr(name),
    module
  );
  return Data_Wrap_Struct(cLLVMFunction, NULL, NULL, f);
}

VALUE
llvm_module_write_bitcode(VALUE self, VALUE file_name) {
  Check_Type(file_name, T_STRING);

  // Don't really know how to handle c++ streams well, 
  // dumping all into string buffer and then saving
  std::ofstream file;
  file.open(StringValuePtr(file_name)); 
  WriteBitcodeToFile(LLVM_MODULE(self), file);   // Convert value into a string.
  return Qtrue;
}

VALUE
llvm_execution_engine_run_function(int argc, VALUE *argv, VALUE klass) {
  if(argc < 1) { rb_raise(rb_eArgError, "Expected at least one argument"); }
  CHECK_TYPE(argv[0], cLLVMFunction);

  // Using run function is much slower than getting C function pointer
  // and calling that, but it lets us pass in arbitrary numbers of
  // arguments easily for now, which is nice
  std::vector<GenericValue> arg_values;
  for(int i = 1; i < argc; ++i) {
    GenericValue arg_val;
    arg_val.IntVal = APInt(sizeof(long)*8, argv[i]);
    arg_values.push_back(arg_val);
  }

  GenericValue v = EE->runFunction(LLVM_FUNCTION(argv[0]), arg_values);
  VALUE val = v.IntVal.getZExtValue();

  return val;
}

/* For tests: assume no args, return uncoverted int and turn it into fixnum */
VALUE llvm_execution_engine_run_autoconvert(VALUE klass, VALUE func) {
  std::vector<GenericValue> args;
  GenericValue v = EE->runFunction(LLVM_FUNCTION(func), args);
  VALUE val = INT2NUM(v.IntVal.getZExtValue());
  return val;
}
}
