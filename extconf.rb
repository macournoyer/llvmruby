require 'mkmf'

extension_name = 'llvmruby'

dir_config(extension_name)

have_library('stdc++')

dir_config('llvm')

with_ldflags(`llvm-config --libs all`) do 
  create_makefile(extension_name)
end

