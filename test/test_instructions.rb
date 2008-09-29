require 'test/unit'
require 'llvm'

include LLVM

class InstructionTests < Test::Unit::TestCase

  def setup

    @assembly_byteswap=<<-EOF
    ; ModuleID = 'byteswap.bc'
    target datalayout = "e-p:32:32:32-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:32:64-f32:32:32-f64:32:64-v64:64:64-v128:128:128-a0:0:64-f80:128:128"
    target triple = "i386-apple-darwin9"

    define i32 @bswap(i32 %x) nounwind {
    entry:
    	%tmp3 = shl i32 %x, 24		; <i32> [#uses=1]
    	%tmp5 = shl i32 %x, 8		; <i32> [#uses=1]
    	%tmp6 = and i32 %tmp5, 16711680		; <i32> [#uses=1]
    	%tmp9 = lshr i32 %x, 8		; <i32> [#uses=1]
    	%tmp1018 = and i32 %tmp9, 65280		; <i32> [#uses=1]
    	%tmp7 = or i32 %tmp1018, %tmp3		; <i32> [#uses=1]
    	%tmp11 = or i32 %tmp7, %tmp6		; <i32> [#uses=1]
    	ret i32 %tmp11
    }
    EOF

  end

  def test_count_intructions_in_basic_block
    m = LLVM::Module.read_assembly(@assembly_byteswap)
    bswap = m.get_function("bswap")
    assert(bswap)

    bbs = bswap.get_basic_block_list
    assert_equal(1,bbs.size)
    b = bbs[0]
    assert_equal(8,b.size)

    expected_opcodes_in_bswap = ["shl", "shl", "and", "lshr", "and", "lshr", "and", "or", "or", "ret"]
    ins = b.get_instruction_list
    actual_opcodes_in_bswap = ins.map { |i| i.get_opcode_name}
    assert(expected_opcodes_in_bswap, actual_opcodes_in_bswap)
  end

end
