import configure::*;
import constants::*;
import wires::*;
import functions::*;

module rs_mem (
    input  logic           reset,
    input  logic           clock,
    input  logic           flush,
    input  rs_mem_in_type  rs_in,
    output rs_mem_out_type rs_out
);
  timeunit 1ns; timeprecision 1ps;

  localparam MEM_ADDR_BITS = $clog2(RS_MEM_DEPTH);

  rs_mem_reg_type r, rin;
  rs_mem_reg_type                     v;

  logic           [ RS_MEM_DEPTH-1:0] ready_vec;
  logic           [MEM_ADDR_BITS-1:0] sel_idx;
  logic                               sel_found;
  logic [MEM_ADDR_BITS-1:0] free_idx0, free_idx1;
  logic free_found0, free_found1;
  rs_entry_type  e;
  rob_entry_type re;
  logic          store_ahead;
  integer ii, jj;

  always_comb begin

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
      e = rs_mem_read(v.array, MEM_ADDR_BITS'(unsigned'(ii)));
      e = rs_wakeup(e, rs_in.cdb0);
      e = rs_wakeup(e, rs_in.cdb1);
      e = rs_wakeup(e, rs_in.cdb_load);
      v.array = rs_mem_write(v.array, MEM_ADDR_BITS'(unsigned'(ii)), e);
    end

    for (ii = 0; ii < RS_MEM_DEPTH; ii++) begin
      e = rs_mem_read(v.array, MEM_ADDR_BITS'(unsigned'(ii)));
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
      e       = rs_mem_read(v.array, sel_idx);
      e.valid = 1'b0;
      v.array = rs_mem_write(v.array, sel_idx, e);
      v.count = v.count - 1;
    end

    if (rs_in.alloc0 && free_found0) begin
      v.array = rs_mem_write(v.array, free_idx0, rs_in.entry0);
      v.count = v.count + 1;
    end
    if (rs_in.alloc1 && free_found1) begin
      v.array = rs_mem_write(v.array, free_idx1, rs_in.entry1);
      v.count = v.count + 1;
    end

    rs_out.issue0       = rs_mem_read(v.array, sel_idx);
    rs_out.issue0_valid = sel_found;
    rs_out.full         = r.count >= (MEM_ADDR_BITS + 1)'(RS_MEM_DEPTH - 1);
    rs_out.has_two_free = r.count <= (MEM_ADDR_BITS + 1)'(RS_MEM_DEPTH - 2);

    rin                 = v;

  end

  always_ff @(posedge clock) begin
    if (reset == 0) begin
      r <= init_rs_mem_reg;
    end else if (flush) begin
      r <= init_rs_mem_reg;
    end else begin
      r <= rin;
    end
  end

endmodule
