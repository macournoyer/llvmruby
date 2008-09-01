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

  def locals
    @@locals
  end
end

class RubyVM
  def initialize
    @module = LLVM::Module.new('ruby_vm')
    ExecutionEngine.get(@module)

    @rb_ary_new = @module.external_function('rb_ary_new', ftype(VALUE, []))
    @rb_ary_store = @module.external_function('rb_ary_store', ftype(VALUE, [VALUE, LONG, VALUE]))
    @rb_to_id = @module.external_function('rb_to_id', ftype(VALUE, [VALUE]))
    @rb_ivar_get = @module.external_function('rb_ivar_get', ftype(VALUE, [VALUE, ID]))
    @rb_ivar_set = @module.external_function('rb_ivar_set', ftype(VALUE, [VALUE, ID, VALUE]))

    @func_n = 0
  end

  def sym2id(sym)
    (sym.id).llvm(Type::Int64Ty)
  end

  def ftype(ret, args)
    Type.function(ret, args)
  end

  def compile_bytecode(bytecode, farg) 
    f = @module.get_or_insert_function("vm_func#{@func_n}", Type.function(VALUE, [VALUE]))
    @func_n += 1

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
        b.push(arg.llvm)
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
      when :opt_aset
        set = b.pop
        idx = b.fix2int(b.pop)
        ary = b.pop
        b.call(@rb_ary_store, ary, idx, set)
        b.push(set)
      when :opt_length
        recv  = b.pop
        len = b.alen(recv)
        len = b.num2fix(len)
        b.push(len)
      when :opt_lt
        obj = b.pop
        recv = b.pop
        x = b.fix2int(recv)
        y = b.fix2int(obj)
        val = b.icmp_slt(x, y)
        val = b.int_cast(val, LONG, false)
        val = b.mul(val, 2.llvm)
        b.push(val)
      when :opt_gt
        obj = b.pop
        recv = b.pop
        x = b.fix2int(recv)
        y = b.fix2int(obj)
        val = b.icmp_sgt(x, y)
        val = b.int_cast(val, LONG, false)
        val = b.mul(val, 2.llvm)
        b.push(val)
      when :opt_ge
        obj = b.pop
        recv = b.pop
        x = b.fix2int(recv)
        y = b.fix2int(obj)
        val = b.icmp_sge(x, y)
        val = b.int_cast(val, LONG, false)
        val = b.mul(val, 2.llvm)
        b.push(val)
      when :jump
        b.br(blocks[arg])
      when :branchif
        v = b.pop
        cmp = b.icmp_eq(v, 0.llvm)
        b.cond_br(cmp, blocks[i+1], blocks[arg])
      when :branchunless
        v = b.pop
        cmp = b.icmp_eq(v, 1.llvm)
        b.cond_br(cmp, blocks[arg], blocks[i+1])
      when :getinstancevariable
        obj = b.pop
        id = b.call(@rb_to_id, arg.llvm)
        v = b.call(@rb_ivar_get, obj, id)
        b.push(v)
      when :setinstancevariable
        new_val = b.pop
        obj = b.peek
        id = b.call(@rb_to_id, arg.llvm)
        b.call(@rb_ivar_set, obj, id, new_val)
      when :newarray
        ary = b.call(@rb_ary_new)
        b.push(ary)
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

    ExecutionEngine.run_function(f, farg)
  end
end
