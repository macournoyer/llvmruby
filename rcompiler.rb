require 'llvm'
include LLVM

VOID = Type::VoidTy
INT = Type::Int32Ty
LONG = Type::Int64Ty
CHAR = Type::Int8Ty
PCHAR = Type.pointer(CHAR)
RSTRING = Type.struct([INT, PCHAR])
PRSTRING = Type.pointer(RSTRING)

class MethodTable
  attr_accessor(:types)
  attr_reader(:funcs)
  attr_reader(:obj_type)

  def initialize(name, m, obj_type, t)
    funcs= {}
    t.each do |k, v|
      ret_type, *arg_types = v
      ftype = Type.function(ret_type, [obj_type] + arg_types)
      fname = "#{name}_method_#{funcs.size}"
      funcs[k] = m.get_or_insert_function(fname, ftype)
    end
    @funcs = funcs
    @obj_type = obj_type
  end
end

class RObject
  attr_accessor(:value)
  attr_accessor(:methods)
end

class Compiler
  attr_accessor(:classes)

  def initialize
    @module = LLVM::Module.new('rruby') 

    # create Kernel
    ftype = Type.function(INT, [PCHAR], true)
    @printf = @module.external_function('printf', ftype)

    ftype = Type.function(PCHAR, [PCHAR, PCHAR], true)
    @sprintf = @module.external_function('sprintf', ftype)

    ftype = Type.function(INT, [PCHAR])
    @strlen = @module.external_function('strlen', ftype)

    classes = {
      :Num => create_num_methods,
      :String => create_str_methods
    }
    @classes = classes

    ftype = Type.function(PRSTRING, [PCHAR])
    @str_from_cstr = @module.get_or_insert_function('String_str_from_cstr', ftype)
    str_from_cstr = @str_from_cstr
    cstr = str_from_cstr.arguments.first
    b = str_from_cstr.create_block.builder
    len = b.call(@strlen, cstr)
    str_obj = b.malloc(RSTRING, 1)
    str_len = b.struct_gep(str_obj, 0)
    b.store(len, str_len)
    str_ptr = b.struct_gep(str_obj, 1)
    b.store(cstr, str_ptr)
    b.return(str_obj)

    @variables = {}
  end

  def create_num_methods
    num_methods = MethodTable.new(
      :Num, @module, INT,
      :+ => [INT, INT],
      :- => [INT, INT],
      :to_s => [PRSTRING]
    )

    num_methods.types = { 
      :+ => :Num,
      :- => :Num,
      :to_s => :String
    }

    f = num_methods.funcs[:+]
    b = f.create_block.builder
    recv, obj = f.arguments
    v = b.add(recv, obj)
    b.return(v)

    f = num_methods.funcs[:-]
    b = f.create_block.builder
    recv, obj = f.arguments
    v = b.sub(recv, obj)
    b.return(v)

    f = num_methods.funcs[:to_s]
    b = f.create_block.builder
    recv = f.arguments.first
    str_buf = b.malloc(CHAR, 33)
    format_str = b.create_global_string_ptr('%d')
    v = b.call(@sprintf, str_buf, format_str, recv)
    str_obj = b.malloc(RSTRING, 1)
    str_ptr = b.struct_gep(str_obj, 1)
    b.store(str_buf, str_ptr) 
    b.return(str_obj)

    num_methods
  end

  def create_str_methods
    str_methods = MethodTable.new(
      :String, @module, PRSTRING,
      :length => [INT],
      :puts => [INT],
      :+ => [PRSTRING, PRSTRING]
    )

    str_methods.types = {
      :length => :Num,
      :puts => :Nil,
      :+ => :String
    }

    f = str_methods.funcs[:length]
    b = f.create_block.builder
    recv = f.arguments.first  
    len_ptr = b.struct_gep(recv, 0)
    len = b.load(len_ptr)
    b.return(len)

    f = str_methods.funcs[:puts]
    b = f.create_block.builder
    recv = f.arguments.first
    str_ptr = b.struct_gep(recv, 1)
    str = b.load(str_ptr)
    b.call(@printf, str)
    b.return(0.llvm(INT))

    str_methods
  end

  def parse_sexpr(sexpr, b)
    type = sexpr.shift
    case type
      when :call
        recv = parse_sexpr(sexpr.shift, b)
        method = sexpr.shift
        arg_vals = [] 
        if args = sexpr.shift 
          puts "processing arguments: #{args.shift}"
          args.map! {|arg| parse_sexpr(arg, b)}
          arg_vals = args.map {|arg| arg.value}
        end
        func = recv.methods.funcs[method]
        ret_type = recv.methods.types[method]
        puts "calling #{method}, return type is #{ret_type}, func: #{func}"
        val = b.call(func, recv.value, *arg_vals)
        obj = RObject.new
        obj.methods = classes[ret_type]
        obj.value = val
        obj
      when :str
        str = sexpr.shift
        puts "adding string literal #{str.inspect}"
        gstr_ptr = b.create_global_string_ptr(str)
        str_val = b.call(@str_from_cstr, gstr_ptr)
        str_obj = RObject.new
        str_obj.methods = classes[:String]
        str_obj.value = str_val
        str_obj
      when :lit
        lit = sexpr.shift
        puts "adding numeric literal #{lit}"
        val = lit.llvm(INT)
        num_obj = RObject.new
        num_obj.methods = classes[:Num]
        num_obj.value = val
        num_obj
      when :lasgn
        var_name = sexpr.shift
        val = parse_sexpr(sexpr.shift, b)
        var = @variables[var_name]
        unless var
          puts "Creating local variable #{var_name.inspect}"
          puts "New object type: #{val.methods.obj_type}"
          var = RObject.new
          var.methods = val.methods
          var.value = b.alloca(val.methods.obj_type, 1)
        end
        b.store(val.value, var.value)
        @variables[var_name] = var
        val
      when :lvar
        var_name = sexpr.shift
        var = @variables[var_name]
        obj = RObject.new
        obj.methods = var.methods
        obj.value = b.load(var.value)
        obj
      else
        puts "diggin deeper..."
        sexpr.each {|s| parse_sexpr(s, b) if Array === s }
    end
  end

  def compile(sexpr)
    main_type = Type.function(INT, [INT, Type.pointer(PCHAR)])
    main = @module.get_or_insert_function('main', main_type)
    b = main.create_block.builder

    parse_sexpr(sexpr, b)
    b.return(0.llvm(INT))

    puts @module.inspect
    @module.write_bitcode("main.o")
  end
end

#sexpr = [:defn, :omg, [:scope, [:block, [:args], [:str, "sheemak"]]]]
#sexpr = [:call, [:call, [:call, [:str, "sheemak"], :length], :to_s], :puts]
#sexpr = [:call, [:call, [:call, [:str, "sheemak"], :length], :to_s], :puts]
#sexpr = [:call, [:call, [:lit, 666], :to_s], :puts]
#sexpr = [:call, [:call, [:call, [:lit, 2], :+, [:array, [:lit, 3]]], :to_s], :puts]
#sexpr = [:lasgn, :x, [:lit, 23]]
#sexpr = [:block, [:lasgn, :x, [:lit, 23]], [:call, [:str, "shaka khan"], :puts]]
#sexpr = [:block, [:lasgn, :x, [:lit, 23]], [:call, [:call, [:lvar, :x], :to_s], :puts]]
sexpr = [:block, 
  [:lasgn, :x, [:lit, 2]], 
  [:lasgn, :y, [:lit, 3]],
  [:lasgn, :x, [:call, [:lvar, :x], :+, [:array, [:lvar, :y]]]],
  [:call, [:call, [:lvar, :x], :to_s], :puts]
]

compiler = Compiler.new
compiler.compile(sexpr)
