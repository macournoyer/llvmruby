require 'llvm'
include LLVM
include RubyInternals

@module = LLVM::Module.new('ruby_vm')
ExecutionEngine.get(@module)

class Builder
  include RubyHelpers

  def self.set_globals(b)
    @@stack = b.alloca(VALUE, 100)
    @@stack_ptr = b.alloca(P_VALUE, 0)
    b.store(@@stack, @@stack_ptr)
    @@locals = b.alloca(VALUE, 100)
  end

  def stack 
    @@stack
  end

  def stack_ptr
    @@stack_ptr
  end

  def push(val)
    sp = load(stack_ptr)
    store(val, sp)
    new_sp = gep(sp, 1.llvm)
    store(new_sp, stack_ptr)
  end 

  def pop
    sp = load(stack_ptr)
    new_sp = gep(sp, -1.llvm)
    store(new_sp, stack_ptr)
    load(new_sp)
  end

  def peek(n = 1)
    sp = load(stack_ptr)
    peek_sp = gep(sp, (-n).llvm)
    load(peek_sp)
  end

  def locals
    @@locals
  end
end

def bytecode_test
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
    [:putobject, 2],
    [:opt_aref] 
  ]

  f = @module.get_or_insert_function('vm_func', Type.function(VALUE, [VALUE]))
  entry_block = f.create_block
  b = entry_block.builder
  Builder.set_globals(b)
  b.push(f.arguments.first)

  blocks = bytecode.map { f.create_block } 
  exit_block = f.create_block
  blocks << exit_block
  b.br(blocks.first)

  bytecode.each_with_index do |opcode, i|
    op, arg = opcode

    block = blocks[i] 
    b = block.builder

    case op
    when :nop
    when :putobject
      b.push(arg.object_id.llvm)
    when :pop
      b.pop
    when :dup
      b.push(b.peek)
    when :swap
      v1 = b.pop
      v2 = b.pop
      b.push(v1)
      b.push(v2)
    when :setlocal
      v = b.pop
      local_slot = b.gep(b.locals, arg.llvm)
      b.store(v, local_slot)
    when :getlocal
      local_slot = b.gep(b.locals, arg.llvm)
      val = b.load(local_slot)
      b.push(val)
    when :opt_plus
      v1 = b.fix2int(b.pop)
      v2 = b.fix2int(b.pop)
      sum = b.add(v1, v2)     
      b.push(b.num2fix(sum))
    when :opt_minus
      v1 = b.fix2int(b.pop)
      v2 = b.fix2int(b.pop)
      sum = b.sub(v2, v1)
      b.push(b.num2fix(sum))
    when :opt_mult
      v1 = b.fix2int(b.pop)
      v2 = b.fix2int(b.pop)
      mul = b.mul(v1, v2)
      b.push(b.num2fix(mul))
    when :opt_aref
      idx = b.fix2int(b.pop)
      ary = b.pop
      out = b.aref(ary, idx)
      b.push(out)
    when :jump
      b.br(blocks[arg])
    when :branchif
      v = b.pop
      cmp = b.icmp_eq(v, 1.llvm)
      b.cond_br(cmp, blocks[i+1], blocks[arg])
    when :branchunless
      v = b.pop
      cmp = b.icmp_eq(v, 1.llvm)
      b.cond_br(cmp, blocks[arg], blocks[i+1])
    else
      raise("Unrecognized op code")
    end

    if op != :jump && op != :branchif && op != :branchunless
      b.br(blocks[i+1])
    end
  end

  b = exit_block.builder
  ret_val = b.pop
  b.return(ret_val)

  ret = ExecutionEngine.run_function(f, [1,2,3,4,5,6,7,8,9,10])
  puts "returned: #{ret}"
end

bytecode_test
