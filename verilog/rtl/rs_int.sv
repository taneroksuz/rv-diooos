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

  typedef struct packed {
    logic [RS_ADDR_BITS:0]   count;
    logic [RS_INT_DEPTH-1:0] valid_bits;
    logic [RS_ADDR_BITS-1:0] sel0_idx;
    logic [RS_ADDR_BITS-1:0] sel1_idx;
    logic                    sel0_found;
    logic                    sel1_found;
    logic [RS_ADDR_BITS-1:0] free_idx0;
    logic [RS_ADDR_BITS-1:0] free_idx1;
    logic                    free_found0;
    logic                    free_found1;
    rs_int_out_type          rs_o;
  } rs_int_reg_type;

  localparam rs_int_out_type init_rs_int_out = '0;

  localparam rs_int_reg_type init_rs_int_reg = '{
      count: '0,
      valid_bits: '0,
      sel0_idx: '0,
      sel1_idx: '0,
      sel0_found: 1'b0,
      sel1_found: 1'b0,
      free_idx0: '0,
      free_idx1: '0,
      free_found0: 1'b0,
      free_found1: 1'b0,
      rs_o: init_rs_int_out
  };

  rs_entry_type array[0:RS_INT_DEPTH-1];
  rs_entry_type view[0:RS_INT_DEPTH-1];
  rs_entry_type woken[0:RS_INT_DEPTH-1];
  logic [RS_INT_DEPTH-1:0] ready_vec;
  rs_int_reg_type r, rin, v;

  always_comb begin
    v = r;
    v.sel0_idx = '0;
    v.sel1_idx = '0;
    v.sel0_found = 1'b0;
    v.sel1_found = 1'b0;
    v.free_idx0 = '0;
    v.free_idx1 = '0;
    v.free_found0 = 1'b0;
    v.free_found1 = 1'b0;
    v.rs_o = init_rs_int_out;

    for (int i = 0; i < RS_INT_DEPTH; i++) begin
      view[i] = r.valid_bits[i] ? array[i] : init_rs_entry;
      view[i].valid = r.valid_bits[i];
      woken[i] = rs_wakeup(view[i], rs_in.cdb0);
      woken[i] = rs_wakeup(woken[i], rs_in.cdb1);
      woken[i] = rs_wakeup(woken[i], rs_in.cdb_load);
      ready_vec[i] = woken[i].valid & woken[i].src1_ready & woken[i].src2_ready;
      if (!woken[i].valid && !v.free_found0) begin
        v.free_idx0   = RS_ADDR_BITS'(unsigned'(i));
        v.free_found0 = 1'b1;
      end else if (!woken[i].valid && !v.free_found1) begin
        v.free_idx1   = RS_ADDR_BITS'(unsigned'(i));
        v.free_found1 = 1'b1;
      end
    end

    for (int i = RS_INT_DEPTH - 1; i >= 0; i--) begin
      if (ready_vec[i]) begin
        v.sel0_idx   = RS_ADDR_BITS'(unsigned'(i));
        v.sel0_found = 1'b1;
      end
    end
    for (int i = RS_INT_DEPTH - 1; i >= 0; i--) begin
      if (ready_vec[i] && (RS_ADDR_BITS'(unsigned'(i)) != v.sel0_idx)) begin
        v.sel1_idx   = RS_ADDR_BITS'(unsigned'(i));
        v.sel1_found = 1'b1;
      end
    end

    if (v.sel0_found) begin
      v.rs_o.issue0 = woken[v.sel0_idx];
    end else begin
      v.rs_o.issue0 = init_rs_entry;
    end
    v.rs_o.issue0_valid = v.sel0_found;
    if (v.sel1_found) begin
      v.rs_o.issue1 = woken[v.sel1_idx];
    end else begin
      v.rs_o.issue1 = init_rs_entry;
    end
    v.rs_o.issue1_valid = v.sel1_found;
    v.rs_o.full = (r.count >= (RS_ADDR_BITS + 1)'(RS_INT_DEPTH - 1));
    v.rs_o.has_two_free = (r.count <= (RS_ADDR_BITS + 1)'(RS_INT_DEPTH - 2));
    v.rs_o.csr_rin = '0;
    v.rs_o.csr_rin.crden = (v.sel0_found && woken[v.sel0_idx].op.csreg) || (v.sel1_found && woken[v.sel1_idx].op.csreg);
    if (v.sel0_found && woken[v.sel0_idx].op.csreg) begin
      v.rs_o.csr_rin.craddr = woken[v.sel0_idx].caddr;
    end else if (v.sel1_found && woken[v.sel1_idx].op.csreg) begin
      v.rs_o.csr_rin.craddr = woken[v.sel1_idx].caddr;
    end

    if (flush) begin
      v.count = '0;
      v.valid_bits = '0;
      v.sel0_found = 1'b0;
      v.sel1_found = 1'b0;
      v.free_found0 = 1'b0;
      v.free_found1 = 1'b0;
      v.rs_o = init_rs_int_out;
    end else begin
      if (v.sel0_found) begin
        v.valid_bits[v.sel0_idx] = 1'b0;
        v.count = v.count - 1'b1;
      end
      if (v.sel1_found) begin
        v.valid_bits[v.sel1_idx] = 1'b0;
        v.count = v.count - 1'b1;
      end
      if (rs_in.alloc0 && v.free_found0) begin
        v.valid_bits[v.free_idx0] = 1'b1;
        v.count = v.count + 1'b1;
      end
      if (rs_in.alloc1 && v.free_found1) begin
        v.valid_bits[v.free_idx1] = 1'b1;
        v.count = v.count + 1'b1;
      end
    end

    rin = v;
    rs_out = rin.rs_o;
  end

  always_ff @(posedge clock) begin
    if (reset == 0) begin
      r <= init_rs_int_reg;
    end else begin
      r <= rin;
    end
  end

  always_ff @(posedge clock) begin
    if (reset != 0) begin
      for (int i = 0; i < RS_INT_DEPTH; i++) begin
        if (rs_in.alloc0 && rin.free_found0 && (rin.free_idx0 == RS_ADDR_BITS'(unsigned'(i)))) begin
          array[i] <= rs_in.entry0;
        end else if (rs_in.alloc1 && rin.free_found1 && (rin.free_idx1 == RS_ADDR_BITS'(unsigned'(i)))) begin
          array[i] <= rs_in.entry1;
        end else if (r.valid_bits[i] && rin.valid_bits[i] &&
                     !((rin.sel0_found && (rin.sel0_idx == RS_ADDR_BITS'(unsigned'(i)))) ||
                       (rin.sel1_found && (rin.sel1_idx == RS_ADDR_BITS'(unsigned'(i)))))) begin
          array[i] <= woken[i];
        end
      end
    end
  end
endmodule
