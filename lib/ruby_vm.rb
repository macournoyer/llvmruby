require 'llvm'
include LLVM
include RubyInternals

class Symbol
  # turn a symbol object_id into a VALUE
  # from gc.c, symbols object_id's are calculated like this:
  # SYM2ID(x) = RSHIFT((unsigned long)x,8)
  # object_id = (SYM2ID(obj) * sizeof(RVALUE) + (4 << 2)) | FIXNUM_FLAG;
  def llvm
    (((object_id/20) << 8) | 0xe).llvm(MACHINE_WORD)
  end
end

class Object
  def llvm
    LLVM::Value.get_immediate_constant(self)
  end

  def llvm_send(f)
    # for now, pass the receiver as the first argument
    ExecutionEngine.runFunction(f, self)
  end
end

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

  def topn(n)
    sp = load(stack_ptr)
    idx = sub((-1).llvm(Type::Int32Ty), n)
    top_sp = gep(sp, idx)
    load(top_sp)
  end

  def locals
    @@locals
  end
end

class OpCodeBuilder
  def initialize(mod, func, rb_funcs)
    @mod = mod
    @func = func
    @rb_funcs = rb_funcs
  end

  def get_self
    @func.arguments.first
  end

  def nop(b, oprnd)
  end

  def putnil(b, oprnd)
    b.push(nil.immediate)
  end

  def putself(b, oprnd)
    b.push(get_self)
  end

  def putobject(b, oprnd)
    b.push(oprnd.llvm)
  end

  def pop(b, oprnd)
    b.pop
  end

  def dup(b, oprnd)
    b.push(b.peek)
  end

  def swap(b, oprn) 
    v1 = b.pop
    v2 = b.pop
    b.push(v1)
    b.push(v2) 
  end

  def setlocal(b, oprnd)
    v = b.pop
    local_slot = b.gep(b.locals, oprnd.llvm)
    b.store(v, local_slot)
  end

  def getlocal(b, oprnd)
    local_slot = b.gep(b.locals, oprnd.llvm)
    val = b.load(local_slot)
    b.push(val)
  end

  def opt_plus(b, oprnd)
    v1 = b.fix2int(b.pop)
    v2 = b.fix2int(b.pop)
    sum = b.add(v1, v2)
    b.push(b.num2fix(sum))
  end

  def opt_minus(b, oprnd)
    v1 = b.fix2int(b.pop)
    v2 = b.fix2int(b.pop)
    sum = b.sub(v2, v1)
    b.push(b.num2fix(sum))
  end

  def opt_mult(b, oprnd)
    v1 = b.fix2int(b.pop)
    v2 = b.fix2int(b.pop)
    mul = b.mul(v1, v2)
    b.push(b.num2fix(mul))
  end

  def opt_aref(b, oprnd)
    idx = b.fix2int(b.pop)
    ary = b.pop
    out = b.aref(ary, idx)
    b.push(out)
  end
  
  def opt_aset(b, oprnd)
    set = b.pop
    idx = b.fix2int(b.pop)
    ary = b.pop
    b.call(@rb_funcs[:rb_ary_store], ary, idx, set)
    b.push(set)
  end

  def opt_length(b, oprnd)
    recv  = b.pop
    len = b.alen(recv)
    len = b.num2fix(len)
    b.push(len)
  end
  
  def opt_lt(b, oprnd)
    obj = b.pop
    recv = b.pop
    x = b.fix2int(recv)
    y = b.fix2int(obj)
    val = b.icmp_slt(x, y)
    val = b.int_cast(val, LONG, false)
    val = b.mul(val, 2.llvm)
    b.push(val)
  end
  
  def opt_gt(b, oprnd)
    obj = b.pop
    recv = b.pop
    x = b.fix2int(recv)
    y = b.fix2int(obj)
    val = b.icmp_sgt(x, y)
    val = b.int_cast(val, LONG, false)
    val = b.mul(val, 2.llvm)
    b.push(val)
  end

  def opt_ge(b, oprnd)
    obj = b.pop
    recv = b.pop
    x = b.fix2int(recv)
    y = b.fix2int(obj)
    val = b.icmp_sge(x, y)
    val = b.int_cast(val, LONG, false)
    val = b.mul(val, 2.llvm)
    b.push(val)
  end

  def getinstancevariable(b, oprnd)
    id = b.call(@rb_funcs[:rb_to_id], oprnd.llvm)
    v = b.call(@rb_funcs[:rb_ivar_get], get_self, id)
    b.push(v)
  end
 
  def setinstancevariable(b, oprnd)
    new_val = b.peek
    id = b.call(@rb_funcs[:rb_to_id], oprnd.llvm)
    b.call(@rb_funcs[:rb_ivar_set], get_self, id, new_val)
  end

  def newarray(b, oprnd)
    ary = b.call(@rb_funcs[:rb_ary_new])
    b.push(ary)
  end
 
  def newhash(b, oprnd)
    hash = b.call(@rb_funcs[:rb_hash_new])
    i = oprnd.llvm(Type::Int32Ty) # This is an integer not a fixnum

    entry_block = @func.create_block
    loop_block = @func.create_block
    exit_block = @func.create_block

    b.br(entry_block)
    b.set_insert_point(entry_block)
    cmp = b.icmp_sgt(i, 0.llvm(Type::Int32Ty)) 
    b.cond_br(cmp, loop_block, exit_block)

    b.set_insert_point(loop_block)
    idx = b.phi(Type::Int32Ty)
    idx.add_incoming(i, entry_block)
    next_idx = b.sub(idx, 2.llvm(Type::Int32Ty))
    idx.add_incoming(next_idx, loop_block)

    n_1 = b.sub(idx, 1.llvm(Type::Int32Ty))
    n_2 = b.sub(idx, 2.llvm(Type::Int32Ty))
    b.call(@rb_funcs[:rb_hash_aset], hash, b.topn(n_1), b.topn(n_2))
    
    cmp = b.icmp_sgt(next_idx, 0.llvm(Type::Int32Ty))
    b.cond_br(cmp, loop_block, exit_block)

    b.set_insert_point(exit_block)
    b.push(hash)
  end

  def send(b, oprnd)
    recv = nil.immediate
    id = b.call(@rb_funcs[:rb_to_id], :inspect.immediate)
    argc = 0.llvm(Type::Int32Ty)
    val = b.call(@rb_funcs[:rb_funcall2], recv, id, argc, b.stack)
    b.push(val)
  end
end

class RubyVM
  def self.start
    @module = LLVM::Module.new('ruby_vm')
    ExecutionEngine.get(@module)

    @rb_ary_new = @module.external_function('rb_ary_new', ftype(VALUE, []))
    @rb_hash_new = @module.external_function('rb_hash_new', ftype(VALUE, []))
    @rb_hash_aset = @module.external_function('rb_hash_aset', ftype(VALUE, [VALUE, VALUE, VALUE]))
    @rb_ary_store = @module.external_function('rb_ary_store', ftype(VALUE, [VALUE, LONG, VALUE]))
    @rb_to_id = @module.external_function('rb_to_id', ftype(VALUE, [VALUE]))
    @rb_ivar_get = @module.external_function('rb_ivar_get', ftype(VALUE, [VALUE, ID]))
    @rb_ivar_set = @module.external_function('rb_ivar_set', ftype(VALUE, [VALUE, ID, VALUE]))
    @rb_funcall2 = @module.external_function('rb_funcall2', ftype(VALUE, [VALUE, ID, INT, P_VALUE]))

    @rb_funcs = {
      :rb_ary_new => @rb_ary_new,
      :rb_hash_new => @rb_hash_new,
      :rb_hash_aset => @rb_hash_aset,
      :rb_ary_store => @rb_ary_store,
      :rb_to_id => @rb_to_id,
      :rb_ivar_get => @rb_ivar_get,
      :rb_ivar_set => @rb_ivar_set,
      :rb_funcall2 => @rb_funcall2
    }

    @func_n = 0
  end

  def self.ftype(ret, args)
    Type.function(ret, args)
  end

  def self.call_bytecode(bytecode, farg)
    f = compile_bytecode(bytecode)
    ExecutionEngine.run_function(f, nil, farg)
  end

  def self.method_send(recv, compiled_method, farg = nil)
    ExecutionEngine.run_function(compiled_method, recv, farg)
  end

  def self.compile_bytecode(bytecode) 
    f = @module.get_or_insert_function("vm_func#{@func_n}", Type.function(VALUE, [VALUE, VALUE]))
    @func_n += 1

    get_self = f.arguments[0]

    entry_block = f.create_block
    b = entry_block.builder
    Builder.set_globals(b)
    b.push(f.arguments[1])

    blocks = bytecode.map { f.create_block } 
    exit_block = f.create_block
    blocks << exit_block
    b.br(blocks.first)

    op_builder = OpCodeBuilder.new(@module, f, @rb_funcs)

    bytecode.each_with_index do |opcode, i|
      op, arg = opcode

      block = blocks[i] 
      b.set_insert_point(block)

      case op
      when :jump
        b.br(blocks[arg])
      when :branchif
        v = b.pop
        cmp = b.icmp_eq(v, 0.llvm)
        b.cond_br(cmp, blocks[i+1], blocks[arg])
      when :branchunless
        v = b.pop
        cmp = b.icmp_eq(v, 0.llvm)
        b.cond_br(cmp, blocks[arg], blocks[i+1])
      else
        op_builder.__send__(op, b, arg)
      end

      if op != :jump && op != :branchif && op != :branchunless
        b.br(blocks[i+1])
      end
    end

    b = exit_block.builder
    ret_val = b.pop
    b.return(ret_val)

    f
  end
end
