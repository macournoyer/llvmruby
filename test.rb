require 'llvm'
require 'benchmark'

include LLVM

@module = LLVM::Module.new('test')
ExecutionEngine.get(@module)

def testf
  type = Type.function(Type::Int64Ty, [Type::Int64Ty])
  f = @module.get_or_insert_function('test', type)
end

def call(f, arg)
  ExecutionEngine.run_function(f, arg)
end

def fib_test
  f = testf
  n = f.argument
  entry_block = f.create_block 
  loop_block = f.create_block
  exit_block = f.create_block

  builder = entry_block.builder

  # Make the counter
  counter = builder.create_alloca(1)
  builder.create_store(Value.get_constant(2), counter)

  # Initialize the array
  space = builder.create_alloca(20)
  v1 = Value.get_constant(1) 
  builder.create_store(v1, space)
  s1 = builder.create_gep(space, v1)
  builder.create_store(v1, s1)

  # Start the loop
  builder.create_br(loop_block)

  builder = loop_block.builder
  current_counter = builder.create_load(counter)
  current_space = builder.create_gep(space, current_counter)
  back_1 = builder.sub(current_counter, v1) 
  back_2 = builder.sub(back_1, v1)
  back_1_space = builder.create_gep(space, back_1)
  back_2_space = builder.create_gep(space, back_2)
  back_1_val = builder.create_load(back_1_space)
  back_2_val = builder.create_load(back_2_space)
  new_val = builder.add(back_1_val, back_2_val) 
  builder.create_store(new_val, current_space)     
  new_counter = builder.create_add(current_counter, v1)
  builder.create_store(new_counter, counter)

  cmp = builder.create_icmpeq(n, new_counter)
  builder.create_cond_br(cmp, exit_block, loop_block)
  
  builder = exit_block.builder
  last_idx = builder.sub(n, v1) 
  last_slot = builder.create_gep(space, current_counter)
  ret_val = builder.create_load(last_slot)
  builder.create_return(ret_val)

  f.compile
  inputs = Array.new(10) {|n| n+3}
  outputs = inputs.map {|n| f.call(n)}
  puts "inputs: #{inputs.inspect}"
  puts "outputs: #{outputs.inspect}"
end
