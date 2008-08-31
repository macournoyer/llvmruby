require 'test/unit'
require 'llvm'
require 'ruby_vm'

include LLVM

class IVarTest
  def initialize
    @shaka = 'khan'
  end
end

class RubyVMTests < Test::Unit::TestCase
  def test_bytecodes
    #bytecode = [
    #  [:putobject, 1],
    #  [:setlocal, 0],
    #  [:dup],
    #  [:getlocal, 0],
    #  [:opt_plus],
    #  [:setlocal, 0],
    #  [:putobject, 1],
    #  [:opt_minus],
    #  [:dup],
    #  [:branchif, 2],
    #  [:getlocal, 0],
    #]

    # Factorial
    #bytecode = [
    #  [:dup],
    #  [:setlocal, 0],
    #  [:putobject, 1],
    #  [:opt_minus],
    #  [:dup],
    #  [:branchunless, 11],
    #  [:dup],
    #  [:getlocal, 0],
    #  [:opt_mult],
    #  [:setlocal, 0],
    #  [:jump, 2],
    #  [:getlocal, 0]
    #] 

    bytecode = [
      [:getinstancevariable, :@shaka]
    ]

    obj = IVarTest.new
   
    vm = RubyVM.new
    assert_equal('khan', vm.compile_bytecode(bytecode, obj))
  end
end
