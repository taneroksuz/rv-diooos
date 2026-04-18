import configure::*;
import constants::*;
import wires::*;
import functions::*;
module rob (
    input  logic          reset,
    input  logic          clock,
    input  logic          flush,
    input  rob_in_type    rob_in,
    output rob_out_type   rob_out,
    output rob_entry_type rob_entries[0:ROB_DEPTH-1]
);
  timeunit 1ns; timeprecision 1ps;

  typedef struct packed {
    logic [ROB_ADDR_BITS-1:0] head;
    logic [ROB_ADDR_BITS-1:0] tail_ptr;
    logic [ROB_ADDR_BITS:0]   count;
    logic [ROB_DEPTH-1:0]     valid_bits;
  } rob_reg_type;

  localparam rob_reg_type init_rob_reg = '{head: '0, tail_ptr: '0, count: '0, valid_bits: '0};

  rob_entry_type array[0:ROB_DEPTH-1];
  rob_reg_type r, rin, v;
  rob_entry_type view[0:ROB_DEPTH-1];
  rob_entry_type h0, h1;
  rob_entry_type alloc_entry0_w, alloc_entry1_w;
  rob_entry_type tmp;
  logic h0_done, h1_done, h0_flush;
  logic commit0, commit1;
  logic alloc0_ok, alloc1_ok;
  logic [ROB_ADDR_BITS-1:0] head1_idx, tail1_idx;

  always_comb begin
    v = r;
    commit0 = 1'b0;
    commit1 = 1'b0;
    alloc0_ok = 1'b0;
    alloc1_ok = 1'b0;
    head1_idx = r.head + ROB_ADDR_BITS'(1);
    tail1_idx = r.tail_ptr;
    h0 = init_rob_entry;
    h1 = init_rob_entry;
    h0_done = 1'b0;
    h1_done = 1'b0;
    h0_flush = 1'b0;
    alloc_entry0_w = rob_in.alloc_entry0;
    alloc_entry1_w = rob_in.alloc_entry1;
    alloc_entry0_w.valid = 1'b1;
    alloc_entry1_w.valid = 1'b1;

    for (int i = 0; i < ROB_DEPTH; i++) begin
      view[i] = r.valid_bits[i] ? array[i] : init_rob_entry;
      view[i].valid = r.valid_bits[i];
      rob_entries[i] = view[i];
    end

    h0                   = view[r.head];
    h1                   = view[head1_idx];
    h0_done              = h0.valid && h0.done && (r.count >= 1);
    h1_done              = h1.valid && h1.done && (r.count >= 2);
    h0_flush             = h0.exception || h0.mret || (h0.jump && (h0.npc != h0.pnpc));

    rob_out              = init_rob_out;
    rob_out.head_ptr     = r.head;
    rob_out.tail_ptr     = r.tail_ptr;
    rob_out.alloc_tag0   = r.tail_ptr;
    rob_out.alloc_tag1   = r.tail_ptr + ROB_ADDR_BITS'(1);
    rob_out.full         = (r.count >= ROB_DEPTH - 1);
    rob_out.has_two_free = (r.count <= ROB_DEPTH - 2);
    rob_out.stall        = (r.count >= ROB_DEPTH - 1);
    rob_out.entry0       = h0;
    rob_out.entry1       = h1;

    if (h0_done) begin
      commit0 = 1'b1;
      if (h1_done && !h0_flush &&
          !h0.store && !h0.fence && !h0.mret &&
          !h0.wfi && !h0.ecall && !h0.ebreak && !h0.csreg) begin
        commit1 = 1'b1;
      end
    end
    rob_out.commit0 = commit0;
    rob_out.commit1 = commit1;

    if (flush) begin
      v = init_rob_reg;
    end else begin
      if (commit0) begin
        v.valid_bits[v.head] = 1'b0;
        v.head = v.head + ROB_ADDR_BITS'(1);
        v.count = v.count - 1'b1;
      end
      if (commit1) begin
        v.valid_bits[v.head] = 1'b0;
        v.head = v.head + ROB_ADDR_BITS'(1);
        v.count = v.count - 1'b1;
      end

      alloc0_ok = rob_in.alloc0 && (v.count < ROB_DEPTH);
      if (alloc0_ok) begin
        v.valid_bits[v.tail_ptr] = 1'b1;
        v.tail_ptr = v.tail_ptr + ROB_ADDR_BITS'(1);
        v.count = v.count + 1'b1;
      end

      alloc1_ok = rob_in.alloc1 && (v.count < ROB_DEPTH);
      if (alloc1_ok) begin
        tail1_idx = v.tail_ptr;
        v.valid_bits[v.tail_ptr] = 1'b1;
        v.tail_ptr = v.tail_ptr + ROB_ADDR_BITS'(1);
        v.count = v.count + 1'b1;
      end
    end

    rin = v;
  end

  always_ff @(posedge clock) begin
    if (reset == 0) begin
      r <= init_rob_reg;
    end else begin
      r <= rin;
    end
  end

  always_ff @(posedge clock) begin
    if (reset != 0) begin
      if (alloc0_ok) begin
        array[r.tail_ptr] <= alloc_entry0_w;
      end
      if (alloc1_ok) begin
        array[tail1_idx] <= alloc_entry1_w;
      end

      if (rob_in.write_en0 && rin.valid_bits[rob_in.write_tag0]) begin
        tmp            = array[rob_in.write_tag0];
        tmp.done       = 1'b1;
        tmp.result     = rob_in.write_entry0.result;
        tmp.exception  = rob_in.write_entry0.exception;
        tmp.ecause     = rob_in.write_entry0.ecause;
        tmp.etval      = rob_in.write_entry0.etval;
        tmp.npc        = rob_in.write_entry0.npc;
        tmp.branch     = rob_in.write_entry0.branch;
        tmp.jump       = rob_in.write_entry0.jump;
        tmp.store_addr = rob_in.write_entry0.store_addr;
        tmp.store_data = rob_in.write_entry0.store_data;
        tmp.store_strb = rob_in.write_entry0.store_strb;
        tmp.cwdata     = rob_in.write_entry0.cwdata;
        array[rob_in.write_tag0] <= tmp;
      end
      if (rob_in.write_en1 && rin.valid_bits[rob_in.write_tag1]) begin
        tmp            = array[rob_in.write_tag1];
        tmp.done       = 1'b1;
        tmp.result     = rob_in.write_entry1.result;
        tmp.exception  = rob_in.write_entry1.exception;
        tmp.ecause     = rob_in.write_entry1.ecause;
        tmp.etval      = rob_in.write_entry1.etval;
        tmp.npc        = rob_in.write_entry1.npc;
        tmp.branch     = rob_in.write_entry1.branch;
        tmp.jump       = rob_in.write_entry1.jump;
        tmp.store_addr = rob_in.write_entry1.store_addr;
        tmp.store_data = rob_in.write_entry1.store_data;
        tmp.store_strb = rob_in.write_entry1.store_strb;
        tmp.cwdata     = rob_in.write_entry1.cwdata;
        array[rob_in.write_tag1] <= tmp;
      end
      if (rob_in.write_en2 && rin.valid_bits[rob_in.write_tag2]) begin
        tmp           = array[rob_in.write_tag2];
        tmp.done      = 1'b1;
        tmp.result    = rob_in.write_entry2.result;
        tmp.exception = rob_in.write_entry2.exception;
        tmp.ecause    = rob_in.write_entry2.ecause;
        tmp.etval     = rob_in.write_entry2.etval;
        array[rob_in.write_tag2] <= tmp;
      end
      if (rob_in.write_en3 && rin.valid_bits[rob_in.write_tag3]) begin
        tmp            = array[rob_in.write_tag3];
        tmp.done       = 1'b1;
        tmp.store_addr = rob_in.write_entry3.store_addr;
        tmp.store_data = rob_in.write_entry3.store_data;
        tmp.store_strb = rob_in.write_entry3.store_strb;
        tmp.exception  = rob_in.write_entry3.exception;
        tmp.ecause     = rob_in.write_entry3.ecause;
        tmp.etval      = rob_in.write_entry3.etval;
        array[rob_in.write_tag3] <= tmp;
      end
    end
  end
endmodule
