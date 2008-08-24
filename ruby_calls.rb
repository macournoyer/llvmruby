require 'llvm'
include LLVM

class Builder
  include RubyHelpers
end

m = LLVM::Module.new('ruby_bindings_example')
ExecutionEngine.get(m)

# Return the last element of an array
type = Type.function(Type::Int64Ty, [Type::Int64Ty])
f = m.get_or_insert_function('last', type)
b = f.create_block.builder
ary = f.arguments.first
len = b.alen(ary)
idx = b.sub(len, 1.llvm)
ret = b.aref(ary, idx)
b.create_return(ret)
last = f

# Swap the first and last elements of an array (in place)
type = Type.function(Type::Int64Ty, [Type::Int64Ty])
f = m.get_or_insert_function('swap', type)
b = f.create_block.builder
ary = f.arguments.first
len = b.alen(ary)
last_idx = b.sub(len, 1.llvm)
idx_x = 0.llvm
idx_y = b.sub(last_idx, idx_x)
x = b.aref(ary, idx_x)
y = b.aref(ary, idx_y)
b.aset(ary, idx_x, y)
b.aset(ary, idx_y, x)
b.create_return(ary)
swap = f

ret = ExecutionEngine.run_function(swap, [1,2,3,4,23])
puts "returned: #{ret.inspect}"
