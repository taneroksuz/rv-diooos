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

  logic [PRF_ADDR_BITS-1:0] list[0:FLIST_DEPTH-1];
  logic [FL_CNT_BITS-1:0] spec_head;
  logic [FL_CNT_BITS-1:0] comm_head;
  logic [FL_CNT_BITS-1:0] tail;
  logic [FL_CNT_BITS-1:0] spec_count;
  logic [FL_CNT_BITS-1:0] comm_count;

  logic [FL_CNT_BITS-1:0] nt, nsc, ncc, nsh, nch;
  logic do_free0, do_free1;
  logic [FL_IDX_BITS-1:0] free0_slot, free1_slot;

  always_comb begin
    nt = tail;
    nsc = spec_count;
    ncc = comm_count;
    nsh = spec_head;
    nch = comm_head;

    do_free0 = fl_in.free_en0 && (nsc < FL_CNT_BITS'(FLIST_DEPTH));
    if (do_free0) begin
      free0_slot = nt[FL_IDX_BITS-1:0];
      nt = nt + 1;
      nsc = nsc + 1;
      nch = nch + 1;
    end else begin
      free0_slot = '0;
    end

    do_free1 = fl_in.free_en1 && (nsc < FL_CNT_BITS'(FLIST_DEPTH));
    if (do_free1) begin
      free1_slot = nt[FL_IDX_BITS-1:0];
      nt = nt + 1;
      nsc = nsc + 1;
      nch = nch + 1;
    end else begin
      free1_slot = '0;
    end

    if (fl_in.alloc0 && nsc >= 1) begin
      nsh = nsh + 1;
      nsc = nsc - 1;
    end

    if (fl_in.alloc1 && nsc >= 2) begin
      nsh = nsh + 1;
      nsc = nsc - 1;
    end

    if (flush) begin
      nsh = nch;
      nsc = ncc;
    end
  end

  assign fl_out.alloc_tag0 = list[spec_head[FL_IDX_BITS-1:0]];
  assign fl_out.alloc_tag1 = list[FL_IDX_BITS'(spec_head+1'b1)];
  assign fl_out.alloc_ok0  = (spec_count >= 1);
  assign fl_out.alloc_ok1  = (spec_count >= 2);
  assign fl_out.empty      = (spec_count == '0);
  assign fl_out.has_two    = (spec_count >= 2);

  always_ff @(posedge clock) begin
    integer i;
    if (reset == 0) begin
      spec_head  <= '0;
      comm_head  <= '0;
      tail       <= FL_CNT_BITS'(FLIST_DEPTH);
      spec_count <= FL_CNT_BITS'(FLIST_DEPTH);
      comm_count <= FL_CNT_BITS'(FLIST_DEPTH);
      for (i = 0; i < FLIST_DEPTH; i++) begin
        list[i] <= PRF_ADDR_BITS'(ARCH_REGS + i);
      end
    end else begin
      spec_head  <= nsh;
      comm_head  <= nch;
      tail       <= nt;
      spec_count <= nsc;
      comm_count <= ncc;
      if (do_free0) list[free0_slot] <= fl_in.free_tag0;
      if (do_free1) list[free1_slot] <= fl_in.free_tag1;
    end
  end

endmodule
