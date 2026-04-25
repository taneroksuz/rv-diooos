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
    logic [FLIST_DEPTH-1:0] list_written;
  } fl_reg_type;
  localparam fl_reg_type init_fl_reg = '{
      spec_head: '0,
      comm_head: '0,
      tail: FL_CNT_BITS'(FLIST_DEPTH),
      spec_count: FL_CNT_BITS'(FLIST_DEPTH),
      comm_count: FL_CNT_BITS'(FLIST_DEPTH),
      list_written: '0
  };

  logic [PRF_ADDR_BITS-1:0] list[0:FLIST_DEPTH-1];
  fl_reg_type r, rin, v;
  logic do_free0, do_free1;
  logic [FL_IDX_BITS-1:0] free0_slot, free1_slot;
  logic [FL_IDX_BITS-1:0] alloc_slot0, alloc_slot1;
  logic [FL_CNT_BITS-1:0] spec_head_p1;

  always_comb begin
    v = r;
    do_free0 = 1'b0;
    do_free1 = 1'b0;
    free0_slot = '0;
    free1_slot = '0;

    alloc_slot0 = r.spec_head[FL_IDX_BITS-1:0];
    spec_head_p1 = r.spec_head + FL_CNT_BITS'(1);
    alloc_slot1 = spec_head_p1[FL_IDX_BITS-1:0];

    fl_out = '0;
    fl_out.alloc_tag0 = r.list_written[alloc_slot0] ? list[alloc_slot0] : (PRF_ADDR_BITS'(ARCH_REGS) + PRF_ADDR_BITS'(alloc_slot0));
    fl_out.alloc_tag1 = r.list_written[alloc_slot1] ? list[alloc_slot1] : (PRF_ADDR_BITS'(ARCH_REGS) + PRF_ADDR_BITS'(alloc_slot1));
    fl_out.alloc_ok0 = (r.spec_count >= 1);
    fl_out.alloc_ok1 = (r.spec_count >= 2);
    fl_out.empty = (r.spec_count == '0);
    fl_out.has_two = (r.spec_count >= 2);

    if (flush) begin
      v.spec_head  = r.comm_head;
      v.comm_head  = r.comm_head;
      v.spec_count = r.comm_count;

      if (fl_in.free_en0) begin
        do_free0                   = 1'b1;
        free0_slot                 = v.tail[FL_IDX_BITS-1:0];
        v.tail                     = v.tail + 1'b1;
        v.spec_head                = v.spec_head + 1'b1;
        v.comm_head                = v.comm_head + 1'b1;
        v.list_written[free0_slot] = 1'b1;
      end

      if (fl_in.free_en1) begin
        do_free1                   = 1'b1;
        free1_slot                 = v.tail[FL_IDX_BITS-1:0];
        v.tail                     = v.tail + 1'b1;
        v.spec_head                = v.spec_head + 1'b1;
        v.comm_head                = v.comm_head + 1'b1;
        v.list_written[free1_slot] = 1'b1;
      end
    end else begin
      if (fl_in.free_en0 && (v.spec_count < FL_CNT_BITS'(FLIST_DEPTH))) begin
        do_free0                   = 1'b1;
        free0_slot                 = v.tail[FL_IDX_BITS-1:0];
        v.tail                     = v.tail + 1'b1;
        v.spec_count               = v.spec_count + 1'b1;
        v.comm_head                = v.comm_head + 1'b1;
        v.list_written[free0_slot] = 1'b1;
      end

      if (fl_in.free_en1 && (v.spec_count < FL_CNT_BITS'(FLIST_DEPTH))) begin
        do_free1                   = 1'b1;
        free1_slot                 = v.tail[FL_IDX_BITS-1:0];
        v.tail                     = v.tail + 1'b1;
        v.spec_count               = v.spec_count + 1'b1;
        v.comm_head                = v.comm_head + 1'b1;
        v.list_written[free1_slot] = 1'b1;
      end

      if (fl_in.alloc0 && (v.spec_count >= 1)) begin
        v.spec_head  = v.spec_head + 1'b1;
        v.spec_count = v.spec_count - 1'b1;
      end
      if (fl_in.alloc1 && (v.spec_count >= 1)) begin
        v.spec_head  = v.spec_head + 1'b1;
        v.spec_count = v.spec_count - 1'b1;
      end
    end
    rin = v;
  end

  always_ff @(posedge clock) begin
    if (reset == 0) begin
      r <= init_fl_reg;
    end else begin
      r <= rin;
    end
  end

  always_ff @(posedge clock) begin
    if (reset != 0) begin
      if (do_free0) begin
        list[free0_slot] <= fl_in.free_tag0;
      end
      if (do_free1) begin
        list[free1_slot] <= fl_in.free_tag1;
      end
    end
  end
endmodule
