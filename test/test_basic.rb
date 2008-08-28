require 'test/unit'
require 'llvm'

include LLVM

class BasicTests < Test::Unit::TestCase
  def function_tester(expected)
    m = LLVM::Module.new("test_module")
    type = Type::function(MACHINE_WORD, [])
    f = m.get_or_insert_function("test", type)
    yield(f)
    ExecutionEngine.get(m);
    assert_equal(expected, ExecutionEngine.run_autoconvert(f))
  end

  def test_module
    function_tester(5) do |f|
      b = f.create_block.builder
      v = b.add(2.llvm, 3.llvm)
      b.return(v)
    end
  end

  def bin_op(op, v1, v2, expected)
    function_tester(expected) do |f|
      b = f.create_block.builder 
      ret = b.bin_op(op, v1.llvm, v2.llvm)
      b.return(ret)
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
      b.return(ret)
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
      builder.br(b2)
      builder.set_insert_point(b2)
      builder.return(2.llvm)
    end
  end

  def test_builder_utils
    function_tester(5) do |f|
      b = f.create_block.builder
      b.write do
        ret = add(2.llvm, 3.llvm) 
        self.return(ret)
      end
    end
  end

  def test_cmps
    m = LLVM::Module.new("test_cmps")
    type = Type.function(MACHINE_WORD, [])
    f = m.get_or_insert_function("sgt", type)
    
    entry_block = f.create_block
    exit_block_true = f.create_block
    exit_block_false = f.create_block
    
    b = entry_block.builder
    cmp = b.icmp_sgt(-1.llvm, 1.llvm)
    b.cond_br(cmp, exit_block_true, exit_block_false)

    b = exit_block_true.builder
    b.return(1.llvm)

    b = exit_block_false.builder
    b.return(0.llvm)
 
    ExecutionEngine.get(m)
    result = ExecutionEngine.run_autoconvert(f)
    assert_equal(0, result)
  end

  def test_function_calls
    m = LLVM::Module.new('test_module')
    type = Type::function(MACHINE_WORD, [])
    f_caller = m.get_or_insert_function("caller", type)
    type = Type::function(MACHINE_WORD, [MACHINE_WORD, MACHINE_WORD])
    f_callee = m.get_or_insert_function("callee", type)

    b = f_callee.create_block.builder
    x, y = f_callee.arguments
    sum = b.add(x, y)
    b.return(sum)
    
    b = f_caller.create_block.builder
    ret = b.call(f_callee, 2.llvm, 3.llvm)
    b.return(ret)

    ExecutionEngine.get(m)
    result = ExecutionEngine.run_autoconvert(f_caller)
    assert_equal(5, result)
  end

  def test_phi_node
    m = LLVM::Module.new('test_module')
    type = Type::function(MACHINE_WORD, [])
    f = m.get_or_insert_function('phi_node', type)

    entry_block = f.create_block
    loop_block = f.create_block
    exit_block = f.create_block

    b = entry_block.builder
    b.br(loop_block)

    b = loop_block.builder
    phi = b.phi(MACHINE_WORD)
    phi.add_incoming(0.llvm, entry_block)
    count = b.add(phi, 1.llvm)
    phi.add_incoming(count, loop_block)
    cmp = b.icmp_ult(count, 10.llvm)
    b.cond_br(cmp, loop_block, exit_block)

    b = exit_block.builder
    b.return(phi)

    ExecutionEngine.get(m)
    result = ExecutionEngine.run_autoconvert(f)
    assert_equal(9, result)
  end

  def test_bitcode_writer
    m = LLVM::Module.new('static_module')
    # create main function
    type = Type.function(Type::Int32Ty, [
      Type::Int32Ty,
      Type.pointer(Type.pointer(Type::Int8Ty))
    ])
    f = m.get_or_insert_function('main', type)
    b = f.create_block.builder
    b.return(666.llvm(Type::Int32Ty))

    m.write_bitcode("test/static.o")
  end

  def test_type_errors
    m = LLVM::Module.new('type_errors')
    ftype = Type.function(Type::Int32Ty, [])
    assert_raise(TypeError) { f = LLVM::Module.new(5) }
    assert_raise(TypeError) { m.get_or_insert_function(5, ftype) }
    assert_raise(TypeError) { m.get_or_insert_function('bad_arg', 5) }
    assert_raise(TypeError) { ExecutionEngine.get(5) }
    assert_raise(TypeError) { m.external_function(5, ftype) }
    assert_raise(TypeError) { m.external_function('fname', 5) }
    assert_raise(TypeError) { m.write_bitcode(5) }
    assert_raise(ArgumentError) { ExecutionEngine.run_function }
    assert_raise(TypeError) { ExecutionEngine.run_function(5) }
    assert_raise(TypeError) { ExecutionEngine.run_function(5, 5) }
   
    f = m.get_or_insert_function('test', ftype) 
    block1 = f.create_block
    block2 = f.create_block
    b = block1.builder
    assert_raise(TypeError) { b.set_insert_point(5) }
    assert_raise(TypeError) { b.phi(5) }
    phi = b.phi(Type::Int32Ty)
    assert_raise(TypeError) { phi.add_incoming(5, 5) }
    assert_raise(TypeError) { phi.add_incoming(5.llvm(Type::Int32Ty), 5) }
    assert_raise(TypeError) { b.bin_op([], 2.llvm, 3.llvm) }
    assert_raise(TypeError) { b.bin_op(Instruction::Add, 5, 3.llvm) }
    assert_raise(TypeError) { b.bin_op(Instruction::Add, 3.llvm, 5) }
  end
end
