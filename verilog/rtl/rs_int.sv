import configure::*;
import constants::*;
import wires::*;

module rs_int (
    input  logic           reset,
    input  logic           clock,
    input  logic           flush,
    input  rs_int_in_type  rs_in,
    output rs_int_out_type rs_out
);
  timeunit 1ns; timeprecision 1ps;

  rs_int_reg_type r, rin;
  rs_int_reg_type v;

  function automatic rs_entry_type rs_read(input rs_int_arr_type arr,
                                           input logic [RS_ADDR_BITS-1:0] idx);
    return arr[idx*RS_SLOT_W+:RS_SLOT_W];
  endfunction

  function automatic rs_int_arr_type rs_write(
      input rs_int_arr_type arr, input logic [RS_ADDR_BITS-1:0] idx, input rs_entry_type entry);
    rs_int_arr_type t;
    t = arr;
    t[idx*RS_SLOT_W+:RS_SLOT_W] = entry;
    return t;
  endfunction

  function automatic rs_entry_type wakeup(input rs_entry_type e, input cdb_type c);
    rs_entry_type t;
    t = e;
    if (c.valid && t.valid) begin
      if (!t.src1_ready && t.psrc1 == c.tag) begin
        t.src1_ready = 1'b1;
        t.rdata1 = c.data;
      end
      if (!t.src2_ready && t.psrc2 == c.tag) begin
        t.src2_ready = 1'b1;
        t.rdata2 = c.data;
      end
    end
    return t;
  endfunction

  always_comb begin
    logic [RS_INT_DEPTH-1:0] ready_vec;
    logic [RS_ADDR_BITS-1:0] sel0_idx, sel1_idx;
    logic sel0_found, sel1_found;
    logic [RS_ADDR_BITS-1:0] free_idx0, free_idx1;
    logic free_found0, free_found1;
    rs_entry_type e;
    integer       ii;

    sel0_idx    = '0;
    sel0_found  = 1'b0;
    sel1_idx    = '0;
    sel1_found  = 1'b0;
    free_idx0   = '0;
    free_found0 = 1'b0;
    free_idx1   = '0;
    free_found1 = 1'b0;
    e           = init_rs_entry;

    v           = r;

    for (ii = 0; ii < RS_INT_DEPTH; ii++) begin
      e = rs_read(v.array, RS_ADDR_BITS'(unsigned'(ii)));
      e = wakeup(e, rs_in.cdb0);
      e = wakeup(e, rs_in.cdb1);
      e = wakeup(e, rs_in.cdb_load);
      v.array = rs_write(v.array, RS_ADDR_BITS'(unsigned'(ii)), e);
    end

    for (ii = 0; ii < RS_INT_DEPTH; ii++) begin
      e = rs_read(v.array, RS_ADDR_BITS'(unsigned'(ii)));
      ready_vec[ii] = e.valid & e.src1_ready & e.src2_ready;
      if (!e.valid && !free_found0) begin
        free_idx0   = RS_ADDR_BITS'(unsigned'(ii));
        free_found0 = 1'b1;
      end else if (!e.valid && free_found0 && !free_found1) begin
        free_idx1   = RS_ADDR_BITS'(unsigned'(ii));
        free_found1 = 1'b1;
      end
    end

    for (ii = RS_INT_DEPTH - 1; ii >= 0; ii--) begin
      if (ready_vec[ii]) begin
        sel0_idx   = RS_ADDR_BITS'(unsigned'(ii));
        sel0_found = 1'b1;
      end
    end
    for (ii = RS_INT_DEPTH - 1; ii >= 0; ii--) begin
      if (ready_vec[ii] && RS_ADDR_BITS'(unsigned'(ii)) != sel0_idx) begin
        sel1_idx   = RS_ADDR_BITS'(unsigned'(ii));
        sel1_found = 1'b1;
      end
    end

    if (sel0_found) begin
      e = rs_read(v.array, sel0_idx);
      e.valid = 1'b0;
      v.array = rs_write(v.array, sel0_idx, e);
      v.count = v.count - 1;
    end
    if (sel1_found) begin
      e = rs_read(v.array, sel1_idx);
      e.valid = 1'b0;
      v.array = rs_write(v.array, sel1_idx, e);
      v.count = v.count - 1;
    end
    if (rs_in.alloc0 && free_found0) begin
      v.array = rs_write(v.array, free_idx0, rs_in.entry0);
      v.count = v.count + 1;
    end
    if (rs_in.alloc1 && free_found1) begin
      v.array = rs_write(v.array, free_idx1, rs_in.entry1);
      v.count = v.count + 1;
    end

    rs_out.issue0       = rs_read(r.array, sel0_idx);
    rs_out.issue0_valid = sel0_found;
    rs_out.issue1       = rs_read(r.array, sel1_idx);
    rs_out.issue1_valid = sel1_found;
    rs_out.full         = r.count >= (RS_ADDR_BITS + 1)'(RS_INT_DEPTH - 1);
    rs_out.has_two_free = r.count <= (RS_ADDR_BITS + 1)'(RS_INT_DEPTH - 2);

    rin                 = v;
  end

  always_ff @(posedge clock) begin
    if (reset == 0 || flush) begin
      r <= init_rs_int_reg;
    end else begin
      r <= rin;
    end
  end

endmodule
