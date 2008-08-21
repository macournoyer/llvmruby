#define __STDC_LIMIT_MACROS

#include "llvm/Module.h"
#include "llvm/DerivedTypes.h"
#include "llvm/Constants.h"
#include "llvm/Instructions.h"
#include "llvm/ModuleProvider.h"
#include "llvm/Analysis/Verifier.h"
#include "llvm/ExecutionEngine/JIT.h"
#include "llvm/ExecutionEngine/Interpreter.h"
#include "llvm/ExecutionEngine/GenericValue.h"
#include <iostream>
using namespace llvm;

#include "ruby.h"

typedef struct {
  Module *M;  
} llvm_module_t;


extern "C" void llvm_module_free(llvm_module_t* data) { 
  cout << "Freeing some crap! " << data->M << "\n";
  if(data->M != NULL) delete data->M;
  cout << "FREED A FUCKIN MODULE\n";
  delete data; 
}

extern "C" VALUE llvm_module_allocate(VALUE klass) { 
  cout << "Allocating module space\n";
  return Data_Wrap_Struct(klass, NULL, llvm_module_free, new llvm_module_t); 
}

extern "C" VALUE llvm_module_initialize(VALUE self) {
  llvm_module_t* data;
  Data_Get_Struct(self, llvm_module_t, data);
  data->M = new Module("jit_test");
  return self;
}
