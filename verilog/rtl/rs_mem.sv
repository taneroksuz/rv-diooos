import configure::*;
import constants::*;
import wires::*;

module rs_mem (
    input  logic           reset,
    input  logic           clock,
    input  rs_mem_in_type  rs_in,
    output rs_mem_out_type rs_out,
    input  logic           flush
);
  timeunit 1ns; timeprecision 1ps;

  localparam MEM_ADDR_BITS = $clog2(RS_MEM_DEPTH);

  rs_mem_reg_type r, rin;
  rs_mem_reg_type v;

  function automatic rs_entry_type rs_read(input rs_mem_arr_type arr,
                                           input logic [MEM_ADDR_BITS-1:0] idx);
    return arr[idx*RS_SLOT_W+:RS_SLOT_W];
  endfunction

  function automatic rs_mem_arr_type rs_write(
      input rs_mem_arr_type arr, input logic [MEM_ADDR_BITS-1:0] idx, input rs_entry_type entry);
    rs_mem_arr_type t;
    t = arr;
    t[idx*RS_SLOT_W+:RS_SLOT_W] = entry;
    return t;
  endfunction

  function automatic rob_entry_type rob_read(input rob_arr_type arr,
                                             input logic [ROB_ADDR_BITS-1:0] idx);
    return arr[idx*ROB_SLOT_W+:ROB_SLOT_W];
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
    logic [ RS_MEM_DEPTH-1:0] ready_vec;
    logic [MEM_ADDR_BITS-1:0] sel_idx;
    logic                     sel_found;
    logic [MEM_ADDR_BITS-1:0] free_idx0, free_idx1;
    logic free_found0, free_found1;
    rs_entry_type  e;
    rob_entry_type re;
    logic          store_ahead;
    integer ii, jj;

    sel_idx     = '0;
    sel_found   = 1'b0;
    free_idx0   = '0;
    free_found0 = 1'b0;
    free_idx1   = '0;
    free_found1 = 1'b0;
    e           = init_rs_entry;
    re          = init_rob_entry;
    store_ahead = 1'b0;

    v           = r;

    for (ii = 0; ii < RS_MEM_DEPTH; ii++) begin
      e = rs_read(v.array, MEM_ADDR_BITS'(unsigned'(ii)));
      e = wakeup(e, rs_in.cdb0);
      e = wakeup(e, rs_in.cdb1);
      e = wakeup(e, rs_in.cdb_load);
      v.array = rs_write(v.array, MEM_ADDR_BITS'(unsigned'(ii)), e);
    end

    for (ii = 0; ii < RS_MEM_DEPTH; ii++) begin
      e = rs_read(v.array, MEM_ADDR_BITS'(unsigned'(ii)));
      ready_vec[ii] = 1'b0;
      if (e.valid && e.src1_ready && e.src2_ready) begin
        if (e.op.load) begin
          store_ahead = 1'b0;
          for (jj = 0; jj < ROB_DEPTH; jj++) begin
            re = rob_read(rs_in.rob_array, ROB_ADDR_BITS'(unsigned'(jj)));
            if (re.valid && re.store && !re.done) store_ahead = 1'b1;
          end
          ready_vec[ii] = !store_ahead;
        end else begin
          store_ahead   = 1'b0;
          ready_vec[ii] = 1'b1;
        end
      end else begin
        store_ahead = 1'b0;
      end
      if (!e.valid && !free_found0) begin
        free_idx0   = MEM_ADDR_BITS'(unsigned'(ii));
        free_found0 = 1'b1;
      end else if (!e.valid && free_found0 && !free_found1) begin
        free_idx1   = MEM_ADDR_BITS'(unsigned'(ii));
        free_found1 = 1'b1;
      end
    end

    for (ii = RS_MEM_DEPTH - 1; ii >= 0; ii--) begin
      if (ready_vec[ii]) begin
        sel_idx   = MEM_ADDR_BITS'(unsigned'(ii));
        sel_found = 1'b1;
      end
    end

    if (sel_found) begin
      e = rs_read(v.array, sel_idx);
      e.valid = 1'b0;
      v.array = rs_write(v.array, sel_idx, e);
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

    rs_out.issue0       = rs_read(r.array, sel_idx);
    rs_out.issue0_valid = sel_found;
    rs_out.full         = r.count >= (MEM_ADDR_BITS + 1)'(RS_MEM_DEPTH - 1);
    rs_out.has_two_free = r.count <= (MEM_ADDR_BITS + 1)'(RS_MEM_DEPTH - 2);

    rin                 = v;
  end

  always_ff @(posedge clock) begin
    if (reset == 0 || flush) begin
      r <= init_rs_mem_reg;
    end else begin
      r <= rin;
    end
  end

endmodule
