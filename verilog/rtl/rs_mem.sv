import configure::*;
import constants::*;
import wires::*;
import functions::*;
module rs_mem (
    input  logic           reset,
    input  logic           clock,
    input  logic           flush,
    input  rs_mem_in_type  rs_in,
    input  rob_entry_type  rob_entries[0:ROB_DEPTH-1],
    output rs_mem_out_type rs_out
);
  timeunit 1ns; timeprecision 1ps;
  localparam MEM_ADDR_BITS = $clog2(RS_MEM_DEPTH);
  rs_entry_type                     array     [0:RS_MEM_DEPTH-1];
  logic         [  MEM_ADDR_BITS:0] count;
  rs_entry_type                     woken     [0:RS_MEM_DEPTH-1];
  logic         [ RS_MEM_DEPTH-1:0] ready_vec;
  logic         [MEM_ADDR_BITS-1:0] sel_idx;
  logic                             sel_found;
  logic [MEM_ADDR_BITS-1:0] free_idx0, free_idx1;
  logic free_found0, free_found1;
  logic store_ahead;
  integer ii, jj;
  always_comb begin
    rs_out      = '0;
    store_ahead = 1'b0;
    sel_idx     = '0;
    sel_found   = 1'b0;
    free_idx0   = '0;
    free_found0 = 1'b0;
    free_idx1   = '0;
    free_found1 = 1'b0;
    for (ii = 0; ii < RS_MEM_DEPTH; ii++) begin
      woken[ii] = rs_wakeup(array[ii], rs_in.cdb0);
      woken[ii] = rs_wakeup(woken[ii], rs_in.cdb1);
      woken[ii] = rs_wakeup(woken[ii], rs_in.cdb_load);
    end
    for (ii = 0; ii < RS_MEM_DEPTH; ii++) begin
      ready_vec[ii] = 1'b0;
      if (woken[ii].valid && woken[ii].src1_ready && woken[ii].src2_ready) begin
        if (woken[ii].op.load) begin
          store_ahead = 1'b0;
          for (jj = 0; jj < ROB_DEPTH; jj++)
          if (rob_entries[jj].valid && rob_entries[jj].store && !rob_entries[jj].done)
            store_ahead = 1'b1;
          ready_vec[ii] = !store_ahead;
        end else ready_vec[ii] = 1'b1;
      end
      if (!woken[ii].valid && !free_found0) begin
        free_idx0   = MEM_ADDR_BITS'(unsigned'(ii));
        free_found0 = 1'b1;
      end else if (!woken[ii].valid && !free_found1) begin
        free_idx1   = MEM_ADDR_BITS'(unsigned'(ii));
        free_found1 = 1'b1;
      end
    end
    for (ii = RS_MEM_DEPTH - 1; ii >= 0; ii--)
    if (ready_vec[ii]) begin
      sel_idx   = MEM_ADDR_BITS'(unsigned'(ii));
      sel_found = 1'b1;
    end
    rs_out.issue0       = sel_found ? woken[sel_idx] : init_rs_entry;
    rs_out.issue0_valid = sel_found;
    rs_out.full         = (count >= (MEM_ADDR_BITS + 1)'(RS_MEM_DEPTH - 1));
    rs_out.has_two_free = (count <= (MEM_ADDR_BITS + 1)'(RS_MEM_DEPTH - 2));
  end
  always_ff @(posedge clock) begin
    integer i;
    logic [MEM_ADDR_BITS:0] nc;
    if (reset == 0 || flush) begin
      count <= '0;
      for (i = 0; i < RS_MEM_DEPTH; i++) array[i] <= init_rs_entry;
    end else begin
      for (i = 0; i < RS_MEM_DEPTH; i++) array[i] <= woken[i];
      nc = count;
      if (sel_found) begin
        array[sel_idx].valid <= 1'b0;
        nc = nc - 1;
      end
      if (rs_in.alloc0 && free_found0) begin
        array[free_idx0] <= rs_in.entry0;
        nc = nc + 1;
      end
      if (rs_in.alloc1 && free_found1) begin
        array[free_idx1] <= rs_in.entry1;
        nc = nc + 1;
      end
      count <= nc;
    end
  end
endmodule
