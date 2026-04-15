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

  (* ramstyle = "M20K, no_rw_check" *) logic [PRF_ADDR_BITS-1:0] list[0:FLIST_DEPTH-1];
  logic [FL_CNT_BITS-1:0] spec_head;
  logic [FL_CNT_BITS-1:0] comm_head;
  logic [FL_CNT_BITS-1:0] tail;
  logic [FL_CNT_BITS-1:0] spec_count;
  logic [FL_CNT_BITS-1:0] comm_count;
  logic [FLIST_DEPTH-1:0] list_written;

  logic [FL_CNT_BITS-1:0] spec_head_n;
  logic [FL_CNT_BITS-1:0] comm_head_n;
  logic [FL_CNT_BITS-1:0] tail_n;
  logic [FL_CNT_BITS-1:0] spec_count_n;
  logic [FL_CNT_BITS-1:0] comm_count_n;
  logic [FLIST_DEPTH-1:0] list_written_n;
  logic do_free0, do_free1;
  logic [FL_IDX_BITS-1:0] free0_slot, free1_slot;
  logic [FL_IDX_BITS-1:0] alloc_slot0, alloc_slot1;
  logic [FL_CNT_BITS-1:0] spec_head_p1;

  always_comb begin
    spec_head_n = spec_head;
    comm_head_n = comm_head;
    tail_n = tail;
    spec_count_n = spec_count;
    comm_count_n = comm_count;
    list_written_n = list_written;
    do_free0 = 1'b0;
    do_free1 = 1'b0;
    free0_slot = '0;
    free1_slot = '0;

    alloc_slot0 = spec_head[FL_IDX_BITS-1:0];
    spec_head_p1 = spec_head + FL_CNT_BITS'(1);
    alloc_slot1 = spec_head_p1[FL_IDX_BITS-1:0];

    fl_out = '0;
    fl_out.alloc_tag0 = list_written[alloc_slot0] ? list[alloc_slot0] : (PRF_ADDR_BITS'(ARCH_REGS) + PRF_ADDR_BITS'(alloc_slot0));
    fl_out.alloc_tag1 = list_written[alloc_slot1] ? list[alloc_slot1] : (PRF_ADDR_BITS'(ARCH_REGS) + PRF_ADDR_BITS'(alloc_slot1));
    fl_out.alloc_ok0 = (spec_count >= 1);
    fl_out.alloc_ok1 = (spec_count >= 2);
    fl_out.empty = (spec_count == '0);
    fl_out.has_two = (spec_count >= 2);

    if (flush) begin
      spec_head_n  = comm_head;
      spec_count_n = comm_count;
    end else begin
      if (fl_in.free_en0 && (spec_count_n < FL_CNT_BITS'(FLIST_DEPTH))) begin
        do_free0 = 1'b1;
        free0_slot = tail_n[FL_IDX_BITS-1:0];
        tail_n = tail_n + 1'b1;
        spec_count_n = spec_count_n + 1'b1;
        comm_head_n = comm_head_n + 1'b1;
        list_written_n[free0_slot] = 1'b1;
      end

      if (fl_in.free_en1 && (spec_count_n < FL_CNT_BITS'(FLIST_DEPTH))) begin
        do_free1 = 1'b1;
        free1_slot = tail_n[FL_IDX_BITS-1:0];
        tail_n = tail_n + 1'b1;
        spec_count_n = spec_count_n + 1'b1;
        comm_head_n = comm_head_n + 1'b1;
        list_written_n[free1_slot] = 1'b1;
      end

      if (fl_in.alloc0 && (spec_count_n >= 1)) begin
        spec_head_n  = spec_head_n + 1'b1;
        spec_count_n = spec_count_n - 1'b1;
      end
      if (fl_in.alloc1 && (spec_count_n >= 1)) begin
        spec_head_n  = spec_head_n + 1'b1;
        spec_count_n = spec_count_n - 1'b1;
      end
    end
  end

  always_ff @(posedge clock) begin
    if (reset == 0) begin
      spec_head <= '0;
      comm_head <= '0;
      tail <= FL_CNT_BITS'(FLIST_DEPTH);
      spec_count <= FL_CNT_BITS'(FLIST_DEPTH);
      comm_count <= FL_CNT_BITS'(FLIST_DEPTH);
      list_written <= '0;
    end else begin
      spec_head <= spec_head_n;
      comm_head <= comm_head_n;
      tail <= tail_n;
      spec_count <= spec_count_n;
      comm_count <= comm_count_n;
      list_written <= list_written_n;

      if (do_free0) begin
        list[free0_slot] <= fl_in.free_tag0;
      end
      if (do_free1) begin
        list[free1_slot] <= fl_in.free_tag1;
      end
    end
  end
endmodule
