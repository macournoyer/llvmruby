#include "llvmruby.h"

extern "C" {

VALUE
llvm_module_allocate(VALUE klass) {
  return Data_Wrap_Struct(klass, NULL, NULL, NULL);
}

VALUE
llvm_module_initialize(VALUE self, VALUE rname) {
  DATA_PTR(self) = new Module(StringValuePtr(rname));
  return self;
}

VALUE
llvm_module_get_or_insert_function(VALUE self, VALUE name, VALUE rtype) {
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
llvm_execution_engine_run_function(VALUE klass, VALUE func, VALUE arg) {
  std::vector<GenericValue> arg_values;

  if(arg != Qnil) {
    GenericValue arg_val;
    arg_val.IntVal = APInt(64, arg);
    arg_values.push_back(arg_val);
  }

  GenericValue v = EE->runFunction(LLVM_FUNCTION(func), arg_values);
  int val = v.IntVal.getSExtValue();

  // For now, nil args means test functions that want automatic conversion to fixnum
  if(arg == Qnil) {  
    val = INT2NUM(val);
  }

  return val;
}
}
