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

  typedef struct packed {
    logic [MEM_ADDR_BITS:0]  count;
    logic [RS_MEM_DEPTH-1:0] valid_bits;
  } rs_mem_reg_type;

  localparam rs_mem_reg_type init_rs_mem_reg = '{count: '0, valid_bits: '0};

  rs_entry_type array[0:RS_MEM_DEPTH-1];
  rs_mem_reg_type r, rin, v;
  rs_entry_type woken[0:RS_MEM_DEPTH-1];
  rs_entry_type cur_entry;
  logic [RS_MEM_DEPTH-1:0] ready_vec;
  logic [MEM_ADDR_BITS-1:0] sel_idx;
  logic sel_found;
  logic [MEM_ADDR_BITS-1:0] free_idx0, free_idx1;
  logic free_found0, free_found1;
  logic store_ahead;
  logic [ROB_ADDR_BITS-1:0] scan_tag;

  always_comb begin
    rs_out = '0;
    v = r;
    sel_idx = '0;
    sel_found = 1'b0;
    free_idx0 = '0;
    free_idx1 = '0;
    free_found0 = 1'b0;
    free_found1 = 1'b0;
    store_ahead = 1'b0;
    scan_tag = '0;

    for (int i = 0; i < RS_MEM_DEPTH; i++) begin
      cur_entry = r.valid_bits[i] ? array[i] : init_rs_entry;
      cur_entry.valid = r.valid_bits[i];
      woken[i] = rs_wakeup(cur_entry, rs_in.cdb0);
      woken[i] = rs_wakeup(woken[i], rs_in.cdb1);
      woken[i] = rs_wakeup(woken[i], rs_in.cdb_load);
      ready_vec[i] = 1'b0;

      if (woken[i].valid && woken[i].src1_ready && woken[i].src2_ready) begin
        if (woken[i].op.load) begin
          store_ahead = 1'b0;
          scan_tag = rs_in.rob_head;
          for (int j = 0; j < ROB_DEPTH; j++) begin
            if (scan_tag != woken[i].rob_tag) begin
              if (rob_entries[scan_tag].valid && (rob_entries[scan_tag].store || rob_entries[scan_tag].load)) begin
                store_ahead = 1'b1;
              end
              scan_tag = scan_tag + ROB_ADDR_BITS'(1);
            end
          end
          ready_vec[i] = !store_ahead;
        end else begin
          ready_vec[i] = 1'b1;
        end
      end

      if (!woken[i].valid && !free_found0) begin
        free_idx0   = MEM_ADDR_BITS'(unsigned'(i));
        free_found0 = 1'b1;
      end else if (!woken[i].valid && !free_found1) begin
        free_idx1   = MEM_ADDR_BITS'(unsigned'(i));
        free_found1 = 1'b1;
      end
    end

    for (int i = RS_MEM_DEPTH - 1; i >= 0; i--) begin
      if (ready_vec[i]) begin
        sel_idx   = MEM_ADDR_BITS'(unsigned'(i));
        sel_found = 1'b1;
      end
    end

    if (sel_found) begin
      rs_out.issue0 = woken[sel_idx];
    end else begin
      rs_out.issue0 = init_rs_entry;
    end
    rs_out.issue0_valid = sel_found;
    rs_out.full = (r.count >= (MEM_ADDR_BITS + 1)'(RS_MEM_DEPTH - 1));
    rs_out.has_two_free = (r.count <= (MEM_ADDR_BITS + 1)'(RS_MEM_DEPTH - 2));

    if (flush) begin
      v = init_rs_mem_reg;
    end else begin
      if (sel_found) begin
        v.valid_bits[sel_idx] = 1'b0;
        v.count = v.count - 1'b1;
      end
      if (rs_in.alloc0 && free_found0) begin
        v.valid_bits[free_idx0] = 1'b1;
        v.count = v.count + 1'b1;
      end
      if (rs_in.alloc1 && free_found1) begin
        v.valid_bits[free_idx1] = 1'b1;
        v.count = v.count + 1'b1;
      end
    end
    rin = v;
  end

  always_ff @(posedge clock) begin
    if (reset == 0) begin
      r <= init_rs_mem_reg;
    end else begin
      r <= rin;
    end
  end

  always_ff @(posedge clock) begin
    if (reset != 0) begin
      for (int i = 0; i < RS_MEM_DEPTH; i++) begin
        if (rs_in.alloc0 && free_found0 && (free_idx0 == MEM_ADDR_BITS'(unsigned'(i)))) begin
          array[i] <= rs_in.entry0;
        end else if (rs_in.alloc1 && free_found1 && (free_idx1 == MEM_ADDR_BITS'(unsigned'(i)))) begin
          array[i] <= rs_in.entry1;
        end else if (r.valid_bits[i] && rin.valid_bits[i] && !(sel_found && (sel_idx == MEM_ADDR_BITS'(unsigned'(i))))) begin
          array[i] <= woken[i];
        end
      end
    end
  end
endmodule
