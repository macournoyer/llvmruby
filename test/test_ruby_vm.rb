require 'test/unit'
require 'llvm'
require 'ruby_vm'

include LLVM

class RubyVMTests < Test::Unit::TestCase
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
    
  def test_getinstancevariable
    bytecode = [
      [:getinstancevariable, :@shaka]
    ]

    obj = Object.new
    obj.instance_variable_set(:@shaka, 'khan')
   
    vm = RubyVM.new
    assert_equal('khan', vm.compile_bytecode(bytecode, obj))
  end

  def test_setinstancevariable
    bytecode = [
      [:putobject, 'puter'],
      [:setinstancevariable, :@fem]
    ]

    obj = Object.new
    vm = RubyVM.new
    vm.compile_bytecode(bytecode, obj)
    assert_equal('puter', obj.instance_variable_get(:@fem))
  end
end
