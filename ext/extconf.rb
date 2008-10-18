require 'mkmf'

extension_name = 'llvmruby'

dir_config(extension_name)
dir_config('llvm', `llvm-config --includedir`.strip, `llvm-config --libdir`.strip)

have_library('stdc++')
have_library('pthread')

with_ldflags(`llvm-config --libs all`) do 
  create_makefile(extension_name)
end

