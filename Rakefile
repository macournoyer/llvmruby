require 'rake/testtask'

desc "Run the tests"
Rake::TestTask.new(:test) do |t|
  t.libs << 'ext'
  t.test_files = FileList['test/test*.rb']
  t.warning = true
end

OBJ = "ext/llvmruby." + Config::CONFIG["DLEXT"]

file "ext/Makefile" do
  #cmd = "extconf.rb --with-llvm-include=`llvm-config --includedir` --with-llvm-lib=`llvm-config --libdir`"
  cmd = 'extconf.rb'
  Dir.chdir("ext") { ruby(cmd) }
end

file OBJ => %w(ext/Makefile) + FileList["ext/*.{cpp,c,h}"] do
  Dir.chdir("ext") { sh "make" }
end

desc "Compile llvmruby extensions"
task :compile => OBJ
task :default => :compile

desc "Remove compiled files"
task :clean do |t|
  for file in FileList.new("ext/*.o", "ext/Makefile", "ext/mkmf.log", OBJ)
    File.delete(file) rescue true
  end
end
