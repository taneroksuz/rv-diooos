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
  rob_entry_type h0, h1;
  rob_entry_type alloc_entry0_w, alloc_entry1_w;
  logic h0_done, h1_done, h0_flush;
  logic commit0, commit1;
  logic alloc0_ok, alloc1_ok;
  logic [ROB_ADDR_BITS-1:0] head1_idx, tail1_idx;
  logic h0_hit0, h0_hit1, h0_hit2, h0_hit3, h0_hit4, h0_hit5;
  logic h1_hit0, h1_hit1, h1_hit2, h1_hit3, h1_hit4, h1_hit5;
  logic wv0, wv1, wv2, wv3, wv4, wv5;

  always_comb begin
    v                    = r;
    commit0              = 1'b0;
    commit1              = 1'b0;
    alloc0_ok            = 1'b0;
    alloc1_ok            = 1'b0;
    head1_idx            = r.head + ROB_ADDR_BITS'(1);
    tail1_idx            = r.tail_ptr;
    h0_done              = 1'b0;
    h1_done              = 1'b0;
    h0_flush             = 1'b0;
    alloc_entry0_w       = rob_in.alloc_entry0;
    alloc_entry1_w       = rob_in.alloc_entry1;
    alloc_entry0_w.valid = 1'b1;
    alloc_entry1_w.valid = 1'b1;

    h0                   = r.valid_bits[r.head] ? array[r.head] : init_rob_entry;
    h0.valid             = r.valid_bits[r.head];
    h1                   = r.valid_bits[head1_idx] ? array[head1_idx] : init_rob_entry;
    h1.valid             = r.valid_bits[head1_idx];

    wv0                  = rob_in.write_en0 && r.valid_bits[rob_in.write_tag0];
    wv1                  = rob_in.write_en1 && r.valid_bits[rob_in.write_tag1];
    wv2                  = rob_in.write_en2 && r.valid_bits[rob_in.write_tag2];
    wv3                  = rob_in.write_en3 && r.valid_bits[rob_in.write_tag3];
    wv4                  = rob_in.write_en4 && r.valid_bits[rob_in.write_tag4];
    wv5                  = rob_in.write_en5 && r.valid_bits[rob_in.write_tag5];

    h0_hit0              = wv0 && (rob_in.write_tag0 == r.head);
    h1_hit0              = wv0 && (rob_in.write_tag0 == head1_idx);
    h0_hit1              = wv1 && (rob_in.write_tag1 == r.head);
    h1_hit1              = wv1 && (rob_in.write_tag1 == head1_idx);
    h0_hit2              = wv2 && (rob_in.write_tag2 == r.head);
    h1_hit2              = wv2 && (rob_in.write_tag2 == head1_idx);
    h0_hit3              = wv3 && (rob_in.write_tag3 == r.head);
    h1_hit3              = wv3 && (rob_in.write_tag3 == head1_idx);
    h0_hit4              = wv4 && (rob_in.write_tag4 == r.head);
    h1_hit4              = wv4 && (rob_in.write_tag4 == head1_idx);
    h0_hit5              = wv5 && (rob_in.write_tag5 == r.head);
    h1_hit5              = wv5 && (rob_in.write_tag5 == head1_idx);

    if (h0_hit0) begin
      h0.done       = 1'b1;
      h0.result     = rob_in.write_entry0.result;
      h0.exception  = rob_in.write_entry0.exception;
      h0.ecause     = rob_in.write_entry0.ecause;
      h0.etval      = rob_in.write_entry0.etval;
      h0.npc        = rob_in.write_entry0.npc;
      h0.branch     = rob_in.write_entry0.branch;
      h0.jump       = rob_in.write_entry0.jump;
      h0.store_addr = rob_in.write_entry0.store_addr;
      h0.store_data = rob_in.write_entry0.store_data;
      h0.store_strb = rob_in.write_entry0.store_strb;
      h0.cwdata     = rob_in.write_entry0.cwdata;
    end
    if (h1_hit0) begin
      h1.done       = 1'b1;
      h1.result     = rob_in.write_entry0.result;
      h1.exception  = rob_in.write_entry0.exception;
      h1.ecause     = rob_in.write_entry0.ecause;
      h1.etval      = rob_in.write_entry0.etval;
      h1.npc        = rob_in.write_entry0.npc;
      h1.branch     = rob_in.write_entry0.branch;
      h1.jump       = rob_in.write_entry0.jump;
      h1.store_addr = rob_in.write_entry0.store_addr;
      h1.store_data = rob_in.write_entry0.store_data;
      h1.store_strb = rob_in.write_entry0.store_strb;
      h1.cwdata     = rob_in.write_entry0.cwdata;
    end
    if (h0_hit1) begin
      h0.done       = 1'b1;
      h0.result     = rob_in.write_entry1.result;
      h0.exception  = rob_in.write_entry1.exception;
      h0.ecause     = rob_in.write_entry1.ecause;
      h0.etval      = rob_in.write_entry1.etval;
      h0.npc        = rob_in.write_entry1.npc;
      h0.branch     = rob_in.write_entry1.branch;
      h0.jump       = rob_in.write_entry1.jump;
      h0.store_addr = rob_in.write_entry1.store_addr;
      h0.store_data = rob_in.write_entry1.store_data;
      h0.store_strb = rob_in.write_entry1.store_strb;
      h0.cwdata     = rob_in.write_entry1.cwdata;
    end
    if (h1_hit1) begin
      h1.done       = 1'b1;
      h1.result     = rob_in.write_entry1.result;
      h1.exception  = rob_in.write_entry1.exception;
      h1.ecause     = rob_in.write_entry1.ecause;
      h1.etval      = rob_in.write_entry1.etval;
      h1.npc        = rob_in.write_entry1.npc;
      h1.branch     = rob_in.write_entry1.branch;
      h1.jump       = rob_in.write_entry1.jump;
      h1.store_addr = rob_in.write_entry1.store_addr;
      h1.store_data = rob_in.write_entry1.store_data;
      h1.store_strb = rob_in.write_entry1.store_strb;
      h1.cwdata     = rob_in.write_entry1.cwdata;
    end
    if (h0_hit2) begin
      h0.done      = 1'b1;
      h0.result    = rob_in.write_entry2.result;
      h0.exception = rob_in.write_entry2.exception;
      h0.ecause    = rob_in.write_entry2.ecause;
      h0.etval     = rob_in.write_entry2.etval;
    end
    if (h1_hit2) begin
      h1.done      = 1'b1;
      h1.result    = rob_in.write_entry2.result;
      h1.exception = rob_in.write_entry2.exception;
      h1.ecause    = rob_in.write_entry2.ecause;
      h1.etval     = rob_in.write_entry2.etval;
    end
    if (h0_hit3) begin
      h0.done      = 1'b1;
      h0.result    = rob_in.write_entry3.result;
      h0.exception = rob_in.write_entry3.exception;
      h0.ecause    = rob_in.write_entry3.ecause;
      h0.etval     = rob_in.write_entry3.etval;
    end
    if (h1_hit3) begin
      h1.done      = 1'b1;
      h1.result    = rob_in.write_entry3.result;
      h1.exception = rob_in.write_entry3.exception;
      h1.ecause    = rob_in.write_entry3.ecause;
      h1.etval     = rob_in.write_entry3.etval;
    end
    if (h0_hit4) begin
      h0.done       = 1'b1;
      h0.store_addr = rob_in.write_entry4.store_addr;
      h0.store_data = rob_in.write_entry4.store_data;
      h0.store_strb = rob_in.write_entry4.store_strb;
      h0.exception  = rob_in.write_entry4.exception;
      h0.ecause     = rob_in.write_entry4.ecause;
      h0.etval      = rob_in.write_entry4.etval;
    end
    if (h1_hit4) begin
      h1.done       = 1'b1;
      h1.store_addr = rob_in.write_entry4.store_addr;
      h1.store_data = rob_in.write_entry4.store_data;
      h1.store_strb = rob_in.write_entry4.store_strb;
      h1.exception  = rob_in.write_entry4.exception;
      h1.ecause     = rob_in.write_entry4.ecause;
      h1.etval      = rob_in.write_entry4.etval;
    end
    if (h0_hit5) begin
      h0.done       = 1'b1;
      h0.store_addr = rob_in.write_entry5.store_addr;
      h0.store_data = rob_in.write_entry5.store_data;
      h0.store_strb = rob_in.write_entry5.store_strb;
      h0.exception  = rob_in.write_entry5.exception;
      h0.ecause     = rob_in.write_entry5.ecause;
      h0.etval      = rob_in.write_entry5.etval;
    end
    if (h1_hit5) begin
      h1.done       = 1'b1;
      h1.store_addr = rob_in.write_entry5.store_addr;
      h1.store_data = rob_in.write_entry5.store_data;
      h1.store_strb = rob_in.write_entry5.store_strb;
      h1.exception  = rob_in.write_entry5.exception;
      h1.ecause     = rob_in.write_entry5.ecause;
      h1.etval      = rob_in.write_entry5.etval;
    end

    for (int i = 0; i < ROB_DEPTH; i++) begin
      rob_entries[i]       = init_rob_entry;
      rob_entries[i].valid = flush ? 1'b0 : r.valid_bits[i];
      rob_entries[i].store = array[i].store;
    end

    h0_done  = h0.valid && h0.done && (r.count >= 1);
    h1_done  = h1.valid && h1.done && (r.count >= 2);
    h0_flush = h0.exception || h0.mret || (h0.jump && (h0.npc != h0.pnpc));

    rob_out  = init_rob_out;
    if (!flush) begin
      rob_out.head_ptr     = r.head;
      rob_out.tail_ptr     = r.tail_ptr;
      rob_out.alloc_tag0   = r.tail_ptr;
      rob_out.alloc_tag1   = r.tail_ptr + ROB_ADDR_BITS'(1);
      rob_out.full         = (r.count >= ROB_DEPTH - 1);
      rob_out.has_two_free = (r.count <= ROB_DEPTH - 2);
      rob_out.stall        = (r.count >= ROB_DEPTH - 1);
      rob_out.entry0       = h0;
      rob_out.entry1       = h1;
    end

    if (h0_done) begin
      commit0 = 1'b1;
      if (h1_done && !h0_flush && !h0.fence && !h0.mret &&
          !h0.wfi && !h0.ecall && !h0.ebreak && !h0.csreg) begin
        commit1 = 1'b1;
      end
    end
    rob_out.commit0 = flush ? 1'b0 : commit0;
    rob_out.commit1 = flush ? 1'b0 : commit1;

    if (flush) begin
      v = init_rob_reg;
    end else begin
      if (commit0) begin
        v.valid_bits[v.head] = 1'b0;
        v.head               = v.head + ROB_ADDR_BITS'(1);
        v.count              = v.count - 1'b1;
      end
      if (commit1) begin
        v.valid_bits[v.head] = 1'b0;
        v.head               = v.head + ROB_ADDR_BITS'(1);
        v.count              = v.count - 1'b1;
      end

      alloc0_ok = rob_in.alloc0 && (v.count < ROB_DEPTH);
      if (alloc0_ok) begin
        v.valid_bits[v.tail_ptr] = 1'b1;
        v.tail_ptr               = v.tail_ptr + ROB_ADDR_BITS'(1);
        v.count                  = v.count + 1'b1;
      end

      alloc1_ok = rob_in.alloc1 && (v.count < ROB_DEPTH);
      if (alloc1_ok) begin
        tail1_idx                = v.tail_ptr;
        v.valid_bits[v.tail_ptr] = 1'b1;
        v.tail_ptr               = v.tail_ptr + ROB_ADDR_BITS'(1);
        v.count                  = v.count + 1'b1;
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
      if (!flush) begin
        if (alloc0_ok) begin
          array[r.tail_ptr] <= alloc_entry0_w;
        end
        if (alloc1_ok) begin
          array[tail1_idx] <= alloc_entry1_w;
        end

        if (rob_in.write_en0 && rin.valid_bits[rob_in.write_tag0]) begin
          array[rob_in.write_tag0].done       <= 1'b1;
          array[rob_in.write_tag0].result     <= rob_in.write_entry0.result;
          array[rob_in.write_tag0].exception  <= rob_in.write_entry0.exception;
          array[rob_in.write_tag0].ecause     <= rob_in.write_entry0.ecause;
          array[rob_in.write_tag0].etval      <= rob_in.write_entry0.etval;
          array[rob_in.write_tag0].npc        <= rob_in.write_entry0.npc;
          array[rob_in.write_tag0].branch     <= rob_in.write_entry0.branch;
          array[rob_in.write_tag0].jump       <= rob_in.write_entry0.jump;
          array[rob_in.write_tag0].store_addr <= rob_in.write_entry0.store_addr;
          array[rob_in.write_tag0].store_data <= rob_in.write_entry0.store_data;
          array[rob_in.write_tag0].store_strb <= rob_in.write_entry0.store_strb;
          array[rob_in.write_tag0].cwdata     <= rob_in.write_entry0.cwdata;
        end
        if (rob_in.write_en1 && rin.valid_bits[rob_in.write_tag1]) begin
          array[rob_in.write_tag1].done       <= 1'b1;
          array[rob_in.write_tag1].result     <= rob_in.write_entry1.result;
          array[rob_in.write_tag1].exception  <= rob_in.write_entry1.exception;
          array[rob_in.write_tag1].ecause     <= rob_in.write_entry1.ecause;
          array[rob_in.write_tag1].etval      <= rob_in.write_entry1.etval;
          array[rob_in.write_tag1].npc        <= rob_in.write_entry1.npc;
          array[rob_in.write_tag1].branch     <= rob_in.write_entry1.branch;
          array[rob_in.write_tag1].jump       <= rob_in.write_entry1.jump;
          array[rob_in.write_tag1].store_addr <= rob_in.write_entry1.store_addr;
          array[rob_in.write_tag1].store_data <= rob_in.write_entry1.store_data;
          array[rob_in.write_tag1].store_strb <= rob_in.write_entry1.store_strb;
          array[rob_in.write_tag1].cwdata     <= rob_in.write_entry1.cwdata;
        end
        if (rob_in.write_en2 && rin.valid_bits[rob_in.write_tag2]) begin
          array[rob_in.write_tag2].done      <= 1'b1;
          array[rob_in.write_tag2].result    <= rob_in.write_entry2.result;
          array[rob_in.write_tag2].exception <= rob_in.write_entry2.exception;
          array[rob_in.write_tag2].ecause    <= rob_in.write_entry2.ecause;
          array[rob_in.write_tag2].etval     <= rob_in.write_entry2.etval;
        end
        if (rob_in.write_en3 && rin.valid_bits[rob_in.write_tag3]) begin
          array[rob_in.write_tag3].done      <= 1'b1;
          array[rob_in.write_tag3].result    <= rob_in.write_entry3.result;
          array[rob_in.write_tag3].exception <= rob_in.write_entry3.exception;
          array[rob_in.write_tag3].ecause    <= rob_in.write_entry3.ecause;
          array[rob_in.write_tag3].etval     <= rob_in.write_entry3.etval;
        end
        if (rob_in.write_en4 && rin.valid_bits[rob_in.write_tag4]) begin
          array[rob_in.write_tag4].done       <= 1'b1;
          array[rob_in.write_tag4].store_addr <= rob_in.write_entry4.store_addr;
          array[rob_in.write_tag4].store_data <= rob_in.write_entry4.store_data;
          array[rob_in.write_tag4].store_strb <= rob_in.write_entry4.store_strb;
          array[rob_in.write_tag4].exception  <= rob_in.write_entry4.exception;
          array[rob_in.write_tag4].ecause     <= rob_in.write_entry4.ecause;
          array[rob_in.write_tag4].etval      <= rob_in.write_entry4.etval;
        end
        if (rob_in.write_en5 && rin.valid_bits[rob_in.write_tag5]) begin
          array[rob_in.write_tag5].done       <= 1'b1;
          array[rob_in.write_tag5].store_addr <= rob_in.write_entry5.store_addr;
          array[rob_in.write_tag5].store_data <= rob_in.write_entry5.store_data;
          array[rob_in.write_tag5].store_strb <= rob_in.write_entry5.store_strb;
          array[rob_in.write_tag5].exception  <= rob_in.write_entry5.exception;
          array[rob_in.write_tag5].ecause     <= rob_in.write_entry5.ecause;
          array[rob_in.write_tag5].etval      <= rob_in.write_entry5.etval;
        end
      end
    end
  end
endmodule
