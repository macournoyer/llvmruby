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
      [:putobject, 0.immediate],
      [:putobject, 'shaka'.immediate],
      [:opt_aset],
      [:pop]
    ]
  
    vm = RubyVM.new
    ret = vm.compile_bytecode(bytecode, nil)
    assert_equal(ret, ['shaka'])
  end

  def opt_cmp_tester(op, truth_table)
    vm = RubyVM.new
    truth_table.each do |x, y, z|
      bytecode = [
        [:putobject, x.immediate],
        [:putobject, y.immediate],
        [op]
      ]
      ret = vm.compile_bytecode(bytecode, nil)
      assert_equal(z, ret) 
    end
  end

  def test_opt_lt
    opt_cmp_tester(:opt_lt, [
      [0, 1, true],
      [1, 0, false],
      [1, 1, false]
    ])
  end

  def test_opt_gt
    opt_cmp_tester(:opt_gt, [
      [0, 1, false],
      [1, 0, true],
      [1, 1, false]
    ])
  end

  def test_opt_ge
    opt_cmp_tester(:opt_ge, [
      [0, 1, false],
      [1, 0, true],
      [1, 1, true]
    ])
  end

  def test_opt_length
    bytecode = [
      [:opt_length]
    ]

    vm = RubyVM.new 
    ret1 = vm.compile_bytecode(bytecode, [])
    assert_equal(0, ret1)

    ret2 = vm.compile_bytecode(bytecode, [1,2,3,4,5])
    assert_equal(5, ret2)
  end

  def test_simple_loop
    bytecode = [
      [:putobject, 1.immediate],
      [:opt_plus],
      [:dup],
      [:putobject, 10.immediate],
      [:opt_lt],
      [:branchif, 0]
    ]

    vm = RubyVM.new
    ret = vm.compile_bytecode(bytecode, 6)
    assert_equal(10, ret)
  end

  def test_array_loop
    bytecode = [
      [:dup],
      [:setlocal, 0],
      [:opt_length],
      [:putobject, 1.immediate],
      [:opt_minus],
      [:dup],
      [:getlocal, 0],
      [:swap],
      [:opt_aref],
      [:putobject, 2.immediate],
      [:opt_mult],
      [:setlocal, 1],
      [:dup],
      [:getlocal, 0],
      [:swap],
      [:getlocal, 1],
      [:opt_aset],
      [:pop],
      [:dup],
      [:putobject, 0.immediate],
      [:opt_gt],
      [:branchif, 3],
      [:getlocal, 0]
    ]

    vm = RubyVM.new
    ret = vm.compile_bytecode(bytecode, [1,2,3,4,5,6])
    assert_equal([2,4,6,8,10,12], ret)
  end
end
