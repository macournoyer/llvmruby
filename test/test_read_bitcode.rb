require 'test/unit'
require 'llvm'

include LLVM

class BitcodeReadTests < Test::Unit::TestCase
  def test_read_bitcode
    bc = File.open("test/byteswap.bc").read
    m = LLVM::Module.read_bitcode(bc)
    assert_match(/define i32 @bswap\(i32 \%x\) nounwind/, m.inspect) 
  end
end
