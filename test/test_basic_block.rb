$:.unshift "#{File.dirname(__FILE__)}/../lib"
$:.unshift "#{File.dirname(__FILE__)}/../ext"

require 'test/unit'
require 'llvm'

include LLVM

class BasicBlockTests < Test::Unit::TestCase

  def setup

    @assembly_gcd=<<-EOF
    ; ModuleID = 'gcd.o'
    target datalayout = "e-p:32:32:32-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:32:64-f32:32:32-f64:32:64-v64:64:64-v128:128:128-a0:0:64-f80:128:128"
    target triple = "i386-apple-darwin9"

    define i32 @gcd(i32 %a, i32 %b) nounwind {
    entry:
    	%tmp2 = icmp eq i32 %a, 0		; <i1> [#uses=1]
    	br i1 %tmp2, label %bb26, label %bb19

    bb5:		; preds = %bb19, %bb11
    	%indvar48 = phi i32 [ %indvar.next49, %bb11 ], [ 0, %bb19 ]		; <i32> [#uses=2]
    	%tmp50 = sub i32 0, %b_addr.0		; <i32> [#uses=1]
    	%tmp51 = mul i32 %indvar48, %tmp50		; <i32> [#uses=1]
    	%a_addr.0.reg2mem.0 = add i32 %tmp51, %a_addr.0		; <i32> [#uses=3]
    	%tmp8 = icmp sgt i32 %a_addr.0.reg2mem.0, %b_addr.0		; <i1> [#uses=1]
    	br i1 %tmp8, label %bb11, label %bb15.split

    bb11:		; preds = %bb5
    	%indvar.next49 = add i32 %indvar48, 1		; <i32> [#uses=1]
    	br label %bb5

    bb15.split:		; preds = %bb5
    	%tmp18 = sub i32 %b_addr.0, %a_addr.0.reg2mem.0		; <i32> [#uses=1]
    	br label %bb19

    bb19:		; preds = %bb15.split, %entry
    	%b_addr.0 = phi i32 [ %tmp18, %bb15.split ], [ %b, %entry ]		; <i32> [#uses=4]
    	%a_addr.0 = phi i32 [ %a_addr.0.reg2mem.0, %bb15.split ], [ %a, %entry ]		; <i32> [#uses=2]
    	%tmp21 = icmp eq i32 %b_addr.0, 0		; <i1> [#uses=1]
    	br i1 %tmp21, label %bb26, label %bb5

    bb26:		; preds = %bb19, %entry
    	%tmp.0 = phi i32 [ %b, %entry ], [ %a_addr.0, %bb19 ]		; <i32> [#uses=1]
    	ret i32 %tmp.0
    }
    EOF

  end


  def test_count_intructions_in_basic_block
    m = LLVM::Module.read_assembly(@assembly_gcd)
    gcd = m.get_function("gcd")
    assert(gcd)

    bbs = gcd.get_basic_block_list
    expected = { 'entry' => 2, 'bb5' => 6, 'bb11' => 2, 'bb15.split' => 2, 'bb19' => 4, 'bb26' => 2 }
    res = Hash.new
    bbs.each { |b|
      res[b.get_name] = b.size
    }
    assert_equal(expected,res)
  end

end
