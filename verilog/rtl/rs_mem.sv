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
  logic [MEM_ADDR_BITS-1:0] sel0_idx, sel1_idx;
  logic sel0_found, sel1_found;
  logic [MEM_ADDR_BITS-1:0] free_idx0, free_idx1;
  logic free_found0, free_found1;
  logic [ROB_ADDR_BITS-1:0] best0_age, best1_age, cand_age;
  logic [ROB_DEPTH-1:0] store_valid;
  logic [ROB_ADDR_BITS-1:0] store_age[0:ROB_DEPTH-1];
  logic older_store_block;
  logic [MEM_ADDR_BITS-1:0] oldest0_idx, oldest1_idx;
  logic oldest0_found, oldest1_found;
  logic oldest0_ready, oldest1_ready;
  logic [1:0] port_busy;

  function automatic logic [ROB_ADDR_BITS-1:0] rob_age(input logic [ROB_ADDR_BITS-1:0] head,
                                                       input logic [ROB_ADDR_BITS-1:0] tag);
    rob_age = tag - head;
  endfunction

  always_comb begin
    rs_out            = '0;
    v                 = r;
    rin               = r;
    sel0_idx          = '0;
    sel1_idx          = '0;
    sel0_found        = 1'b0;
    sel1_found        = 1'b0;
    free_idx0         = '0;
    free_idx1         = '0;
    free_found0       = 1'b0;
    free_found1       = 1'b0;
    best0_age         = '0;
    best1_age         = '0;
    cand_age          = '0;
    older_store_block = 1'b0;
    oldest0_idx       = '0;
    oldest1_idx       = '0;
    oldest0_found     = 1'b0;
    oldest1_found     = 1'b0;
    oldest0_ready     = 1'b0;
    oldest1_ready     = 1'b0;
    port_busy         = rs_in.load_busy;

    for (int i = 0; i < RS_MEM_DEPTH; i++) begin
      cur_entry       = r.valid_bits[i] ? array[i] : init_rs_entry;
      cur_entry.valid = r.valid_bits[i];
      woken[i]        = rs_wakeup(cur_entry, rs_in.cdb0);
      woken[i]        = rs_wakeup(woken[i], rs_in.cdb1);
      woken[i]        = rs_wakeup(woken[i], rs_in.cdb_load0);
      woken[i]        = rs_wakeup(woken[i], rs_in.cdb_load1);
      woken[i]        = rs_wakeup(woken[i], rs_in.cdb_commit0);
      woken[i]        = rs_wakeup(woken[i], rs_in.cdb_commit1);

      if (woken[i].valid) begin
        cand_age = rob_age(rs_in.rob_head, woken[i].rob_tag);
        if (!oldest0_found || (cand_age < best0_age)) begin
          if (oldest0_found) begin
            oldest1_idx   = oldest0_idx;
            oldest1_found = 1'b1;
            best1_age     = best0_age;
          end
          oldest0_idx   = MEM_ADDR_BITS'(unsigned'(i));
          oldest0_found = 1'b1;
          best0_age     = cand_age;
        end else if (!oldest1_found || (cand_age < best1_age)) begin
          oldest1_idx   = MEM_ADDR_BITS'(unsigned'(i));
          oldest1_found = 1'b1;
          best1_age     = cand_age;
        end
      end

    end

    for (int j = 0; j < ROB_DEPTH; j++) begin
      store_valid[j] = rob_entries[j].valid && rob_entries[j].store;
      store_age[j]   = rob_age(rs_in.rob_head, ROB_ADDR_BITS'(unsigned'(j)));
    end

    if (oldest0_found) begin
      older_store_block = 1'b0;
      if (woken[oldest0_idx].op.load) begin
        for (int j = 0; j < ROB_DEPTH; j++) begin
          if (store_valid[j] && (store_age[j] < best0_age)) begin
            older_store_block = 1'b1;
          end
        end
      end
      oldest0_ready = woken[oldest0_idx].src1_ready && woken[oldest0_idx].src2_ready &&
                      (woken[oldest0_idx].op.store || (woken[oldest0_idx].op.load && !older_store_block));
    end
    if (oldest1_found) begin
      older_store_block = 1'b0;
      if (woken[oldest1_idx].op.load) begin
        for (int j = 0; j < ROB_DEPTH; j++) begin
          if (store_valid[j] && (store_age[j] < best1_age)) begin
            older_store_block = 1'b1;
          end
        end
      end
      oldest1_ready = woken[oldest1_idx].src1_ready && woken[oldest1_idx].src2_ready &&
                      (woken[oldest1_idx].op.store || (woken[oldest1_idx].op.load && !older_store_block));
    end
    sel0_found = 1'b0;
    sel1_found = 1'b0;
    if (oldest0_found && oldest0_ready) begin
      if (!port_busy[0]) begin
        sel0_idx   = oldest0_idx;
        sel0_found = 1'b1;
      end else if (!port_busy[1]) begin
        sel1_idx   = oldest0_idx;
        sel1_found = 1'b1;
      end
    end
    if (sel0_found && oldest1_found && oldest1_ready) begin
      if (!(woken[oldest0_idx].op.load ^ woken[oldest1_idx].op.load)) begin
        if (!port_busy[1]) begin
          sel1_idx   = oldest1_idx;
          sel1_found = 1'b1;
        end
      end
    end

    for (int i = 0; i < RS_MEM_DEPTH; i++) begin
      logic free_cond;
      free_cond = (!woken[i].valid ||
                   (sel0_found && (sel0_idx == MEM_ADDR_BITS'(unsigned'(i)))) ||
                   (sel1_found && (sel1_idx == MEM_ADDR_BITS'(unsigned'(i)))));
      if (free_cond && !free_found0) begin
        free_idx0   = MEM_ADDR_BITS'(unsigned'(i));
        free_found0 = 1'b1;
      end else if (free_cond && !free_found1) begin
        free_idx1   = MEM_ADDR_BITS'(unsigned'(i));
        free_found1 = 1'b1;
      end
    end

    if (sel0_found) begin
      rs_out.issue0 = woken[sel0_idx];
    end else begin
      rs_out.issue0 = init_rs_entry;
    end
    if (sel1_found) begin
      rs_out.issue1 = woken[sel1_idx];
    end else begin
      rs_out.issue1 = init_rs_entry;
    end
    rs_out.issue0_valid = sel0_found;
    rs_out.issue1_valid = sel1_found;
    rs_out.full         = (r.count >= (MEM_ADDR_BITS + 1)'(RS_MEM_DEPTH - 1));
    rs_out.has_two_free = (r.count <= (MEM_ADDR_BITS + 1)'(RS_MEM_DEPTH - 2));

    if (flush) begin
      rs_out      = '0;
      sel0_found  = 1'b0;
      sel1_found  = 1'b0;
      free_found0 = 1'b0;
      free_found1 = 1'b0;
      v           = init_rs_mem_reg;
    end else begin
      if (sel0_found) begin
        v.valid_bits[sel0_idx] = 1'b0;
        v.count                = v.count - 1'b1;
      end
      if (sel1_found) begin
        v.valid_bits[sel1_idx] = 1'b0;
        v.count                = v.count - 1'b1;
      end
      if (rs_in.alloc0 && free_found0) begin
        v.valid_bits[free_idx0] = 1'b1;
        v.count                 = v.count + 1'b1;
      end
      if (rs_in.alloc1 && free_found1) begin
        v.valid_bits[free_idx1] = 1'b1;
        v.count                 = v.count + 1'b1;
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
      if (!flush) begin
        for (int i = 0; i < RS_MEM_DEPTH; i++) begin
          if (rs_in.alloc0 && free_found0 && (free_idx0 == MEM_ADDR_BITS'(unsigned'(i)))) begin
            array[i] <= rs_in.entry0;
          end else if (rs_in.alloc1 && free_found1 && (free_idx1 == MEM_ADDR_BITS'(unsigned'(i)))) begin
            array[i] <= rs_in.entry1;
          end else if (r.valid_bits[i] && rin.valid_bits[i] &&
                       !(sel0_found && (sel0_idx == MEM_ADDR_BITS'(unsigned'(i)))) &&
                       !(sel1_found && (sel1_idx == MEM_ADDR_BITS'(unsigned'(i))))) begin
            array[i] <= woken[i];
          end
        end
      end
    end
  end
endmodule
