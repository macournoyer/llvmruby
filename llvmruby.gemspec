require "./lib/version"

spec = Gem::Specification.new do |s|
    s.platform      = Gem::Platform::RUBY
    s.name          = "llvmruby"
    s.version       = LLVM::Version::STRING
    s.summary       = "Ruby bindings to LLVM"
    s.authors       = [ "Thomas Bagby" ]
    s.email         = [ "tomatobagby@gmail.com" ]
    s.files         = Dir.glob("{doc,ext,lib,test}/**/*")
    s.require_path  = "lib"

    s.extensions    << 'ext/extconf.rb'

    s.test_files    = Dir.glob('test/test_*.rb')
    s.has_rdoc      = true
    s.extra_rdoc_files =   [
      "README",
      "COPYING"
      ]

end
