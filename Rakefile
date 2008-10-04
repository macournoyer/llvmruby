require 'rake/testtask'

desc "Run the tests"
Rake::TestTask.new(:test) do |t|
  t.test_files = FileList['test/test*.rb']
  t.warning = true
end

OBJ = "llvmruby." + Config::CONFIG["DLEXT"]

file "Makefile" do
  ruby "extconf.rb --with-llvm-include=`llvm-config --includedir` --with-llvm-lib=`llvm-config --libdir`"
end
file OBJ => "Makefile" do
  sh "make"
end
desc "Compile llvmruby extensions"
task :compile => OBJ
task :default => :compile