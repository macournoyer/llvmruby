require 'test/unit'
$:.unshift File.dirname(__FILE__) + "/../ext"
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

  def test_fcmps
    m = LLVM::Module.new('test_fcmps')
    type = Type.function(MACHINE_WORD, [])
    f = m.get_or_insert_function('ult', type)
  
    entry_block = f.create_block
    exit_block_true = f.create_block
    exit_block_false = f.create_block
  
    b = entry_block.builder
    cmp = b.fcmp_ult(1.0.llvm, 2.0.llvm)
    b.cond_br(cmp, exit_block_true, exit_block_false)

    b = exit_block_true.builder
    b.return(0.llvm)

    b = exit_block_false.builder
    b.return(1.llvm)

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

  def test_inspectors
    m = LLVM::Module.new('example')
    ftype = Type.function(Type::Int32Ty, [])
    f = m.get_or_insert_function('inspect', ftype)
    b = f.create_block.builder
    b.return(5.llvm(Type::Int32Ty))
    
    assert_match(/define i32 @inspect\(\)/, m.inspect)
    assert_match(/define i32 @inspect\(\)/, f.inspect)
  end

  def test_global_strings
    m = LLVM::Module.new('globalstrings')
    ftype = Type.function(Type::Int32Ty, [])
    f = m.get_or_insert_function('use_global_strings', ftype)
    b = f.create_block.builder
    v = b.create_global_string_ptr("SHAKA KHAN")
  end

  def test_var_arg_ftypes
    ftype = Type.function(Type::Int32Ty, [], true)
  end

  def test_struct_constants
    int_t = Type::Int32Ty
    struct_type = Type.struct([int_t, int_t, int_t])
    struct_const = Value.get_struct_constant(struct_type, 2.llvm(int_t), 3.llvm(int_t), 5.llvm(int_t))
    assert_kind_of(Value, struct_const)

    m = LLVM::Module.new('globals')
    gv = m.global_variable(struct_type, struct_const)
    assert_kind_of(Value, gv)
  end

  def test_malloc_free
    function_tester(23) do |f|
      b = f.create_block.builder
      new_space = b.malloc(MACHINE_WORD, 1)
      assert_kind_of(AllocationInst, new_space)
      assert(!new_space.array_allocation?)
      assert_kind_of(Value, new_space.array_size)
      assert_kind_of(Type, new_space.allocated_type)
      assert_equal(0, new_space.alignment)

      store_inst = b.store(23.llvm(MACHINE_WORD), new_space)    
      assert(store_inst.may_write_to_memory?)
      v = b.load(new_space)
      free_inst = b.free(new_space)
      assert_kind_of(FreeInst, free_inst)
      b.return(v)
    end
  end

  def test_cast
    function_tester(5) do |f|
      b = f.create_block.builder
      b.return(b.cast(Instruction::FPToSI, 5.0.llvm, MACHINE_WORD))
    end
  end

  def test_switch
    function_tester(23) do |f|
      b = f.create_block.builder
      default = f.create_block
      on5 = f.create_block
      switch = b.switch(5.llvm, default)
      switch.add_case(5.llvm, on5)
      assert_instance_of(SwitchInst, switch)
      assert_equal(2, switch.get_num_cases);
      
      b = default.builder
      b.return(7.llvm(MACHINE_WORD))

      b = on5.builder
      b.return(23.llvm)
    end
  end

  def test_vector
    function_tester(666) do |f|
      b = f.create_block.builder
      vt = Type.vector(MACHINE_WORD, 3) 
      vp = b.alloca(vt, 0)
      v = b.load(vp) 
      v2 = b.insert_element(v, 666.llvm(MACHINE_WORD), 0.llvm(Type::Int32Ty))
      r = b.extract_element(v2, 0.llvm(Type::Int32Ty))
      b.return(r)
    end
  end

  def test_pass_manager_run
    m = LLVM::Module.new('test')
    assert PassManager.new.run(m)
  end
  
  def test_type_to_s
    assert_equal "i32", 2.llvm.type.to_s
  end

  def test_type_type_id
    assert_equal IntegerTyID, 2.llvm.type.type_id
  end
end
