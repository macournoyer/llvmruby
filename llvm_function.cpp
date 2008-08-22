#include "llvmruby.h"

typedef struct {
  Module *M;
  Function* F;
  long(*FP)(long);  
} llvm_function_t;

extern "C" {
void llvm_function_free(llvm_function_t* data) { delete data; }
VALUE llvm_function_allocate(VALUE klass) { 
  return Data_Wrap_Struct(klass, NULL, llvm_function_free, new llvm_function_t); 
}

VALUE llvm_function_call(VALUE self, VALUE n) {
  llvm_function_t* data;
  Data_Get_Struct(self, llvm_function_t, data);
  return INT2NUM(data->FP(FIX2INT(n))); 
}

VALUE llvm_function_call2(VALUE self, VALUE n) {
  llvm_function_t* data;
  Data_Get_Struct(self, llvm_function_t, data);
  return data->FP(n);
}

ExecutionEngine *EE = NULL;

VALUE llvm_function_compile(VALUE self) {
  //cout << "Compiling!\n";
  
  llvm_function_t* data;
  Data_Get_Struct(self, llvm_function_t, data);

/*
  PassManager p;
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

  if(EE == NULL) {
    ExistingModuleProvider *MP = new ExistingModuleProvider(data->M);
    EE = ExecutionEngine::create(MP, false);
  }

  //std::cerr << "verifying... ";
  if (verifyModule(*data->M)) {
    std::cerr << "Error constructing function!\n";
  }
  //std::cerr << "\n" << *data->M;
  data->FP = (long(*)(long))EE->getPointerToFunction(data->F);
  return Qnil;
}

VALUE llvm_function_initialize(VALUE self) {
  llvm_function_t* data;
  Data_Get_Struct(self, llvm_function_t, data);

  Module *M = new Module("jit_test");
  data->M = M;
  data->F = cast<Function>(M->getOrInsertFunction("fib", Type::Int64Ty, Type::Int64Ty, (Type *)0));
  
  return self; 
}

VALUE llvm_function_create_block(VALUE self) {
  llvm_function_t* data;
  Data_Get_Struct(self, llvm_function_t, data);
  BasicBlock *bb = BasicBlock::Create("bb", data->F);
  return llvm_basic_block_wrap(bb);
}

VALUE llvm_function_argument(VALUE self) {
  llvm_function_t* data;
  Data_Get_Struct(self, llvm_function_t, data);
  Value *arg = data->F->arg_begin();
  return llvm_value_wrap(arg);
}
}
