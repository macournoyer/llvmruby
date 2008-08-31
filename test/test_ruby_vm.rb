require 'test/unit'
require 'llvm'
require 'ruby_vm'

include LLVM

class RubyVMTests < Test::Unit::TestCase
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

  def test_opt_aset
    bytecode = [
      [:newarray],
      [:dup],
      [:putobject, LLVM::Value.get_immediate_constant(0)],
      [:putobject, LLVM::Value.get_immediate_constant('shaka')],
      [:opt_aset],
      [:pop]
    ]
  
    vm = RubyVM.new
    ret = vm.compile_bytecode(bytecode, nil)
    assert_equal(ret, ['shaka'])
  end

  def test_opt_lt
    bytecode1 = [
      [:putobject, LLVM::Value.get_immediate_constant(0)],
      [:putobject, LLVM::Value.get_immediate_constant(1)],
      [:opt_lt]
    ]

    bytecode2 = [
      [:putobject, LLVM::Value.get_immediate_constant(1)],
      [:putobject, LLVM::Value.get_immediate_constant(0)],
      [:opt_lt]
    ]

    vm = RubyVM.new
    ret1 = vm.compile_bytecode(bytecode1, nil)
    assert_equal(true, ret1)
 
    ret2 = vm.compile_bytecode(bytecode2, nil)
    assert_equal(false, ret2)
  end
end
