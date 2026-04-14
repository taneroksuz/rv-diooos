import configure::*;
import wires::*;
import functions::*;
module fl (
    input  logic       reset,
    input  logic       clock,
    input  logic       flush,
    input  fl_in_type  fl_in,
    output fl_out_type fl_out
);
  timeunit 1ns; timeprecision 1ps;

  typedef struct packed {
    logic [FL_CNT_BITS-1:0] spec_head;
    logic [FL_CNT_BITS-1:0] comm_head;
    logic [FL_CNT_BITS-1:0] tail;
    logic [FL_CNT_BITS-1:0] spec_count;
    logic [FL_CNT_BITS-1:0] comm_count;
  } fl_reg_type;

  localparam fl_reg_type init_fl_reg = '{
      spec_head: '0,
      comm_head: '0,
      tail: FL_CNT_BITS'(FLIST_DEPTH),
      spec_count: FL_CNT_BITS'(FLIST_DEPTH),
      comm_count: FL_CNT_BITS'(FLIST_DEPTH)
  };

  logic [PRF_ADDR_BITS-1:0] list[0:FLIST_DEPTH-1] = '{
      0: PRF_ADDR_BITS'(ARCH_REGS + 0),
      1: PRF_ADDR_BITS'(ARCH_REGS + 1),
      2: PRF_ADDR_BITS'(ARCH_REGS + 2),
      3: PRF_ADDR_BITS'(ARCH_REGS + 3),
      4: PRF_ADDR_BITS'(ARCH_REGS + 4),
      5: PRF_ADDR_BITS'(ARCH_REGS + 5),
      6: PRF_ADDR_BITS'(ARCH_REGS + 6),
      7: PRF_ADDR_BITS'(ARCH_REGS + 7),
      8: PRF_ADDR_BITS'(ARCH_REGS + 8),
      9: PRF_ADDR_BITS'(ARCH_REGS + 9),
      10: PRF_ADDR_BITS'(ARCH_REGS + 10),
      11: PRF_ADDR_BITS'(ARCH_REGS + 11),
      12: PRF_ADDR_BITS'(ARCH_REGS + 12),
      13: PRF_ADDR_BITS'(ARCH_REGS + 13),
      14: PRF_ADDR_BITS'(ARCH_REGS + 14),
      15: PRF_ADDR_BITS'(ARCH_REGS + 15),
      16: PRF_ADDR_BITS'(ARCH_REGS + 16),
      17: PRF_ADDR_BITS'(ARCH_REGS + 17),
      18: PRF_ADDR_BITS'(ARCH_REGS + 18),
      19: PRF_ADDR_BITS'(ARCH_REGS + 19),
      20: PRF_ADDR_BITS'(ARCH_REGS + 20),
      21: PRF_ADDR_BITS'(ARCH_REGS + 21),
      22: PRF_ADDR_BITS'(ARCH_REGS + 22),
      23: PRF_ADDR_BITS'(ARCH_REGS + 23),
      24: PRF_ADDR_BITS'(ARCH_REGS + 24),
      25: PRF_ADDR_BITS'(ARCH_REGS + 25),
      26: PRF_ADDR_BITS'(ARCH_REGS + 26),
      27: PRF_ADDR_BITS'(ARCH_REGS + 27),
      28: PRF_ADDR_BITS'(ARCH_REGS + 28),
      29: PRF_ADDR_BITS'(ARCH_REGS + 29),
      30: PRF_ADDR_BITS'(ARCH_REGS + 30),
      31: PRF_ADDR_BITS'(ARCH_REGS + 31)
  };
  fl_reg_type r, rin;
  fl_reg_type v;
  logic do_free0, do_free1;
  logic [FL_IDX_BITS-1:0] free0_slot, free1_slot;
  always_comb begin
    v = r;

    do_free0 = fl_in.free_en0 && (v.spec_count < FL_CNT_BITS'(FLIST_DEPTH));
    if (do_free0) begin
      free0_slot   = v.tail[FL_IDX_BITS-1:0];
      v.tail       = v.tail + 1'b1;
      v.spec_count = v.spec_count + 1'b1;
      v.comm_head  = v.comm_head + 1'b1;
    end else begin
      free0_slot = '0;
    end

    do_free1 = fl_in.free_en1 && (v.spec_count < FL_CNT_BITS'(FLIST_DEPTH));
    if (do_free1) begin
      free1_slot   = v.tail[FL_IDX_BITS-1:0];
      v.tail       = v.tail + 1'b1;
      v.spec_count = v.spec_count + 1'b1;
      v.comm_head  = v.comm_head + 1'b1;
    end else begin
      free1_slot = '0;
    end

    if (fl_in.alloc0 && v.spec_count >= 1) begin
      v.spec_head  = v.spec_head + 1'b1;
      v.spec_count = v.spec_count - 1'b1;
    end
    if (fl_in.alloc1 && v.spec_count >= 1) begin
      v.spec_head  = v.spec_head + 1'b1;
      v.spec_count = v.spec_count - 1'b1;
    end
    if (flush) begin
      v.spec_head  = v.comm_head;
      v.spec_count = v.comm_count;
    end

    rin = v;
  end

  assign fl_out.alloc_tag0 = list[r.spec_head[FL_IDX_BITS-1:0]];
  assign fl_out.alloc_tag1 = list[FL_IDX_BITS'(r.spec_head+1'b1)];
  assign fl_out.alloc_ok0  = (r.spec_count >= 1);
  assign fl_out.alloc_ok1  = (r.spec_count >= 2);
  assign fl_out.empty      = (r.spec_count == '0);
  assign fl_out.has_two    = (r.spec_count >= 2);

  always_ff @(posedge clock) begin
    if (reset == 0) begin
      r <= init_fl_reg;
    end else begin
      r <= rin;
      if (do_free0) list[free0_slot] <= fl_in.free_tag0;
      if (do_free1) list[free1_slot] <= fl_in.free_tag1;
    end
  end
endmodule
