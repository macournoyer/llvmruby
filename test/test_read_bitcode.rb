require 'test/unit'
require 'llvm'

include LLVM

class BitcodeReadTests < Test::Unit::TestCase

  def test_read_bitcode
    bc = File.open("test/byteswap.bc").read
    m = LLVM::Module.read_bitcode(bc)
    assert_match(/define i32 @bswap\(i32 \%x\) nounwind/, m.inspect) 
  end

  def test_read_assembly
    assembly =<<-END_ASSEMBLY
    ; ModuleID = 'test/byteswap.bc'
    target datalayout = "e-p:32:32:32-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:32:64-f3
    2:32:32-f64:32:64-v64:64:64-v128:128:128-a0:0:64-f80:128:128"
    target triple = "i386-apple-darwin9"

    define i32 @bswap(i32 %x) nounwind {
    entry:
            %tmp3 = shl i32 %x, 24          ; <i32> [#uses=1]
            %tmp5 = shl i32 %x, 8           ; <i32> [#uses=1]
            %tmp6 = and i32 %tmp5, 16711680         ; <i32> [#uses=1]
            %tmp9 = lshr i32 %x, 8          ; <i32> [#uses=1]
            %tmp1018 = and i32 %tmp9, 65280         ; <i32> [#uses=1]
            %tmp7 = or i32 %tmp1018, %tmp3          ; <i32> [#uses=1]
            %tmp11 = or i32 %tmp7, %tmp6            ; <i32> [#uses=1]
            ret i32 %tmp11
    }
    END_ASSEMBLY
    m = LLVM::Module.read_assembly(assembly)
    assert_match(/define i32 @bswap\(i32 \%x\) nounwind/, m.inspect)
    assert(m.get_function("bswap"))
  end

end
