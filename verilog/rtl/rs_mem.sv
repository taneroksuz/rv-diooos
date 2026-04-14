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

  typedef struct packed {logic [MEM_ADDR_BITS:0] count;} rs_mem_reg_type;

  localparam rs_mem_reg_type init_rs_mem_reg = '{count: '0};

  rs_entry_type array[0:RS_MEM_DEPTH-1] = '{default: init_rs_entry};
  rs_mem_reg_type r, rin;
  rs_mem_reg_type                     v;
  rs_entry_type                       woken     [0:RS_MEM_DEPTH-1];
  logic           [ RS_MEM_DEPTH-1:0] ready_vec;
  logic           [MEM_ADDR_BITS-1:0] sel_idx;
  logic                               sel_found;
  logic [MEM_ADDR_BITS-1:0] free_idx0, free_idx1;
  logic free_found0, free_found1;
  logic store_ahead;
  logic [ROB_ADDR_BITS-1:0] scan_tag;

  always_comb begin
    rs_out      = '0;
    store_ahead = 1'b0;
    sel_idx     = '0;
    sel_found   = 1'b0;
    free_idx0   = '0;
    free_found0 = 1'b0;
    free_idx1   = '0;
    free_found1 = 1'b0;
    scan_tag    = '0;
    for (int ii = 0; ii < RS_MEM_DEPTH; ii++) begin
      woken[ii] = rs_wakeup(array[ii], rs_in.cdb0);
      woken[ii] = rs_wakeup(woken[ii], rs_in.cdb1);
      woken[ii] = rs_wakeup(woken[ii], rs_in.cdb_load);
    end
    for (int ii = 0; ii < RS_MEM_DEPTH; ii++) begin
      ready_vec[ii] = 1'b0;
      if (woken[ii].valid && woken[ii].src1_ready && woken[ii].src2_ready) begin
        if (woken[ii].op.load) begin
          store_ahead = 1'b0;
          scan_tag = rs_in.rob_head;
          for (int jj = 0; jj < ROB_DEPTH; jj++) begin
            if (scan_tag != woken[ii].rob_tag) begin
              if (rob_entries[scan_tag].valid && (rob_entries[scan_tag].store || rob_entries[scan_tag].load))
                store_ahead = 1'b1;
              scan_tag = scan_tag + ROB_ADDR_BITS'(1);
            end
          end
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
    for (int ii = RS_MEM_DEPTH - 1; ii >= 0; ii--)
    if (ready_vec[ii]) begin
      sel_idx   = MEM_ADDR_BITS'(unsigned'(ii));
      sel_found = 1'b1;
    end
    rs_out.issue0       = sel_found ? woken[sel_idx] : init_rs_entry;
    rs_out.issue0_valid = sel_found;
    rs_out.full         = (r.count >= (MEM_ADDR_BITS + 1)'(RS_MEM_DEPTH - 1));
    rs_out.has_two_free = (r.count <= (MEM_ADDR_BITS + 1)'(RS_MEM_DEPTH - 2));
  end

  always_comb begin
    v = r;
    if (flush) begin
      v = init_rs_mem_reg;
    end else begin
      if (sel_found) v.count = v.count - 1'b1;
      if (rs_in.alloc0 && free_found0) v.count = v.count + 1'b1;
      if (rs_in.alloc1 && free_found1) v.count = v.count + 1'b1;
    end
    rin = v;
  end

  always_ff @(posedge clock) begin
    if (reset == 0) begin
      r <= init_rs_mem_reg;
    end else begin
      r <= rin;
      if (flush) begin
        for (int i = 0; i < RS_MEM_DEPTH; i++) begin
          array[i].valid      <= 1'b0;
          array[i].src1_ready <= 1'b0;
          array[i].src2_ready <= 1'b0;
        end
      end else begin
        for (int i = 0; i < RS_MEM_DEPTH; i++) array[i] <= woken[i];
        if (sel_found) array[sel_idx].valid <= 1'b0;
        if (rs_in.alloc0 && free_found0) array[free_idx0] <= rs_in.entry0;
        if (rs_in.alloc1 && free_found1) array[free_idx1] <= rs_in.entry1;
      end
    end
  end
endmodule
