require 'test/unit'
require 'llvm'

include LLVM

class BasicTests < Test::Unit::TestCase
  def function_tester(expected)
    m = LLVM::Module.new("test_module")
    type = Type::function(Type::Int64Ty, [])
    f = m.get_or_insert_function("test", type)
    yield(f)
    ExecutionEngine.get(m);
    assert_equal(expected, ExecutionEngine.run_autoconvert(f))
  end

  def test_module
    function_tester(5) do |f|
      b = f.create_block.builder
      v = b.add(2.llvm, 3.llvm)
      b.create_return(v)
    end
  end

  def bin_op(op, v1, v2, expected)
    function_tester(expected) do |f|
      b = f.create_block.builder 
      ret = b.bin_op(op, v1.llvm, v2.llvm)
      b.create_return(ret)
    end
  end

  def test_bin_ops
    bin_op(Instruction::Add, 2, 3, 5)
    bin_op(Instruction::Sub, 5, 3, 2)
    bin_op(Instruction::Mul, 2, 3, 6)
    bin_op(Instruction::UDiv, 42, 6, 7)
    bin_op(Instruction::SDiv, 42, 6, 7)
    #bin_op(Instruction::FDiv, 23.0, 5, 0.23)
    bin_op(Instruction::URem, 23, 5, 3)
    bin_op(Instruction::SRem, 23, 5, 3)
    #bin_op(Instruction::FRem, 23.0, 5, 0.23)

    bin_op(Instruction::Shl, 2, 1, 4)
    bin_op(Instruction::LShr, 8, 1, 4)
    #bin_op(Instruction::AShr, 8, 1, 4) 
    bin_op(Instruction::And, 8, 15, 8)
    bin_op(Instruction::Or, 8, 15, 15)
    bin_op(Instruction::Xor, 8, 15, 7)
  end

  def builder_bin_op(op, v1, v2, expected)
    function_tester(expected) do |f|
      b = f.create_block.builder
      ret = b.send(op, v1.llvm, v2.llvm)
      b.create_return(ret)
    end
  end

  def test_builder_bin_ops
    builder_bin_op(:add, 23, 42, 65)
    builder_bin_op(:sub, 69, 13, 56)
    builder_bin_op(:mul, 23, 5, 115)
    builder_bin_op(:udiv, 23, 5, 4)
    builder_bin_op(:sdiv, 99, 33, 3)
    #builder_bin_op(:fdiv, 23, 42, 65)
    builder_bin_op(:urem, 23, 42, 23)
    builder_bin_op(:srem, 77, 5, 2)
    #builder_bin_op(:frem, 23, 42, 65)
    builder_bin_op(:shl, 15, 1, 30)
    builder_bin_op(:lshr, 32, 2, 8)
    #builder_bin_op(:ashr, 23, 42, 65)
    builder_bin_op(:and, 32, 37, 32)
    builder_bin_op(:or, 15, 8, 15)
    builder_bin_op(:xor, 33, 15, 46)
  end

  def test_insert_point
    function_tester(2) do |f|
      b1 = f.create_block
      b2 = f.create_block
      builder = b1.builder
      builder.create_br(b2)
      builder.set_insert_point(b2)
      builder.create_return(2.llvm)
    end
  end

  def test_builder_utils
    function_tester(5) do |f|
      b = f.create_block.builder
      b.write do
        ret = add(2.llvm, 3.llvm) 
        create_return(ret)
      end
    end
  end

  def test_cmps
    m = LLVM::Module.new("test_cmps")
    type = Type.function(Type::Int64Ty, [])
    f = m.get_or_insert_function("sgt", type)
    
    entry_block = f.create_block
    exit_block_true = f.create_block
    exit_block_false = f.create_block
    
    b = entry_block.builder
    cmp = b.icmp_sgt(-1.llvm, 1.llvm)
    b.create_cond_br(cmp, exit_block_true, exit_block_false)

    b = exit_block_true.builder
    b.create_return(1.llvm)

    b = exit_block_false.builder
    b.create_return(0.llvm)
 
    ExecutionEngine.get(m)
    result = ExecutionEngine.run_autoconvert(f)
    assert_equal(0, result)
  end

  def test_function_calls
    m = LLVM::Module.new("test_module")
    type = Type::function(Type::Int64Ty, [])
    f_caller = m.get_or_insert_function("caller", type)
    type = Type::function(Type::Int64Ty, [Type::Int64Ty, Type::Int64Ty])
    f_callee = m.get_or_insert_function("callee", type)

    b = f_callee.create_block.builder
    x, y = f_callee.arguments
    sum = b.add(x, y)
    b.create_return(sum)
    
    b = f_caller.create_block.builder
    ret = b.create_call(f_callee, 2.llvm, 3.llvm)
    b.create_return(ret)

    ExecutionEngine.get(m)
    result = ExecutionEngine.run_autoconvert(f_caller)
    assert_equal(5, result)
  end

  def test_phi_node
    m = LLVM::Module.new("test_module")
    type = Type::function(Type::Int64Ty, [])
    f = m.get_or_insert_function("phi_node", type)

    entry_block = f.create_block
    loop_block = f.create_block
    exit_block = f.create_block

    b = entry_block.builder
    b.create_br(loop_block)

    b = loop_block.builder
    phi = b.create_phi(Type::Int64Ty)
    phi.add_incoming(0.llvm, entry_block)
    count = b.add(phi, 1.llvm)
    phi.add_incoming(count, loop_block)
    cmp = b.create_icmpult(count, 10.llvm)
    b.create_cond_br(cmp, loop_block, exit_block)

    b = exit_block.builder
    b.create_return(phi)

    ExecutionEngine.get(m)
    result = ExecutionEngine.run_autoconvert(f)
    assert_equal(9, result)
  end

  #def test_get_global
  #  f = Function.new("test_get_global", Type::Int64Ty, [Type::Int64Ty])
  #  b = f.create_block.builder
  #  vp = b.get_global
  #  v = b.create_load(vp)
  #  b.create_return(v)
  #  f.compile
  #  assert_equal(23, f.call2(0))
  #end
end
