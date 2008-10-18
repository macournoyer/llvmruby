require 'rubygems/specification'

spec = Gem::Specification.new do |s|
    s.platform      = Gem::Platform::RUBY
    s.name          = "llvmruby"
    s.version       = "0.0.1" # Can't require version file on Github
    s.summary       = "Ruby bindings to LLVM"
    s.authors       = [ "Thomas Bagby" ]
    s.email         = [ "tomatobagby@gmail.com" ]
    s.files         = [ 
      "README", "COPYING", "Rakefile",
      "lib/llvm.rb", "lib/ruby_vm.rb", "lib/version.rb",
      "ext/llvm_basicblock.cpp",
      "ext/llvm_function.cpp",
      "ext/llvm_instruction.cpp",
      "ext/llvm_module.cpp", 
      "ext/llvm_value.cpp",
      "ext/llvmruby.c",
      "ext/llvmruby.h",
      "ext/extconf.rb",
      "test/test_basic.rb",
      "test/test_basic_block.rb",
      "test/test_instructions.rb",
      "test/test_read_bitcode.rb",
      "test/test_ruby_vm.rb",
      "test/byteswap.bc",
      "test/static.o"
    ]
    s.require_path  = "lib"
    s.extensions    << 'ext/extconf.rb'
    s.test_files    = [
      "test/test_basic.rb",
      "test/test_basic_block.rb",
      "test/test_instructions.rb",
      "test/test_read_bitcode.rb",
      "test/test_ruby_vm.rb",
    ]

    s.has_rdoc      = true
    s.extra_rdoc_files =   [
      "README",
      "COPYING"
    ]
end
