#define __STDC_LIMIT_MACROS

#include "llvm/Module.h"
#include "llvm/DerivedTypes.h"
#include "llvm/Constants.h"
#include "llvm/Instructions.h"
#include "llvm/ModuleProvider.h"
#include "llvm/PassManager.h"
#include "llvm/LinkAllPasses.h"
#include "llvm/Target/TargetData.h"
#include "llvm/Transforms/Scalar.h"
#include "llvm/Analysis/Verifier.h"
#include "llvm/ExecutionEngine/JIT.h"
#include "llvm/ExecutionEngine/Interpreter.h"
#include "llvm/ExecutionEngine/GenericValue.h"
#include "llvm/Support/IRBuilder.h"
#include <iostream>
using namespace llvm;

#include "ruby.h"

extern "C" VALUE llvm_value_wrap(Value*);
extern "C" VALUE llvm_basic_block_wrap(BasicBlock*);
extern "C" VALUE llvm_function_create_block(VALUE);
