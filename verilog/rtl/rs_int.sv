import configure::*;
import constants::*;
import wires::*;
import functions::*;
module rs_int (
    input  logic           reset,
    input  logic           clock,
    input  logic           flush,
    input  rs_int_in_type  rs_in,
    output rs_int_out_type rs_out
);
  timeunit 1ns; timeprecision 1ps;

  typedef struct packed {logic [RS_ADDR_BITS:0] count;} rs_int_reg_type;

  localparam rs_int_reg_type init_rs_int_reg = '{count: '0};

  rs_entry_type array[0:RS_INT_DEPTH-1] = '{default: init_rs_entry};
  rs_int_reg_type r, rin;
  rs_int_reg_type                    v;
  rs_entry_type                      woken     [0:RS_INT_DEPTH-1];
  logic           [RS_INT_DEPTH-1:0] ready_vec;
  logic [RS_ADDR_BITS-1:0] sel0_idx, sel1_idx;
  logic sel0_found, sel1_found;
  logic [RS_ADDR_BITS-1:0] free_idx0, free_idx1;
  logic free_found0, free_found1;

  always_comb begin
    sel0_idx = '0;
    sel0_found = 1'b0;
    sel1_idx = '0;
    sel1_found = 1'b0;
    free_idx0 = '0;
    free_found0 = 1'b0;
    free_idx1 = '0;
    free_found1 = 1'b0;
    for (int ii = 0; ii < RS_INT_DEPTH; ii++) begin
      woken[ii] = rs_wakeup(array[ii], rs_in.cdb0);
      woken[ii] = rs_wakeup(woken[ii], rs_in.cdb1);
      woken[ii] = rs_wakeup(woken[ii], rs_in.cdb_load);
    end
    for (int ii = 0; ii < RS_INT_DEPTH; ii++) begin
      ready_vec[ii] = woken[ii].valid & woken[ii].src1_ready & woken[ii].src2_ready;
      if (!woken[ii].valid && !free_found0) begin
        free_idx0   = RS_ADDR_BITS'(unsigned'(ii));
        free_found0 = 1'b1;
      end else if (!woken[ii].valid && !free_found1) begin
        free_idx1   = RS_ADDR_BITS'(unsigned'(ii));
        free_found1 = 1'b1;
      end
    end
    for (int ii = RS_INT_DEPTH - 1; ii >= 0; ii--)
    if (ready_vec[ii]) begin
      sel0_idx   = RS_ADDR_BITS'(unsigned'(ii));
      sel0_found = 1'b1;
    end
    for (int ii = RS_INT_DEPTH - 1; ii >= 0; ii--)
    if (ready_vec[ii] && RS_ADDR_BITS'(unsigned'(ii)) != sel0_idx) begin
      sel1_idx   = RS_ADDR_BITS'(unsigned'(ii));
      sel1_found = 1'b1;
    end
    rs_out.issue0 = sel0_found ? woken[sel0_idx] : init_rs_entry;
    rs_out.issue0_valid = sel0_found;
    rs_out.issue1 = sel1_found ? woken[sel1_idx] : init_rs_entry;
    rs_out.issue1_valid = sel1_found;
    rs_out.full = (r.count >= (RS_ADDR_BITS + 1)'(RS_INT_DEPTH - 1));
    rs_out.has_two_free = (r.count <= (RS_ADDR_BITS + 1)'(RS_INT_DEPTH - 2));

    rs_out.csr_rin.crden  = (sel0_found && woken[sel0_idx].op.csreg) || (sel1_found && woken[sel1_idx].op.csreg);
    rs_out.csr_rin.craddr = woken[sel0_idx].op.csreg ? woken[sel0_idx].caddr : woken[sel1_idx].caddr;
  end

  always_comb begin
    v = r;
    if (flush) begin
      v = init_rs_int_reg;
    end else begin
      if (sel0_found) v.count = v.count - 1'b1;
      if (sel1_found) v.count = v.count - 1'b1;
      if (rs_in.alloc0 && free_found0) v.count = v.count + 1'b1;
      if (rs_in.alloc1 && free_found1) v.count = v.count + 1'b1;
    end
    rin = v;
  end

  always_ff @(posedge clock) begin
    if (reset == 0) begin
      r <= init_rs_int_reg;
    end else begin
      r <= rin;
      if (flush) begin
        for (int i = 0; i < RS_INT_DEPTH; i++) begin
          array[i].valid      <= 1'b0;
          array[i].src1_ready <= 1'b0;
          array[i].src2_ready <= 1'b0;
        end
      end else begin
        for (int i = 0; i < RS_INT_DEPTH; i++) array[i] <= woken[i];
        if (sel0_found) array[sel0_idx].valid <= 1'b0;
        if (sel1_found) array[sel1_idx].valid <= 1'b0;
        if (rs_in.alloc0 && free_found0) array[free_idx0] <= rs_in.entry0;
        if (rs_in.alloc1 && free_found1) array[free_idx1] <= rs_in.entry1;
      end
    end
  end
endmodule
