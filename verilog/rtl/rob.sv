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
  } rob_reg_type;

  localparam rob_reg_type init_rob_reg = '{head: '0, tail_ptr: '0, count: '0};

  rob_entry_type array[0:ROB_DEPTH-1] = '{default: init_rob_entry};
  rob_reg_type r, rin;
  rob_reg_type v;
  rob_entry_type h0, h1;
  logic h0_done, h1_done;
  logic h0_flush;
  assign rob_entries = array;
  always_comb begin
    h0                  = array[r.head];
    h1                  = array[r.head+1'b1];
    h0_done             = h0.valid && h0.done && (r.count >= 1);
    h1_done             = h1.valid && h1.done && (r.count >= 2);
    h0_flush            = h0.exception || h0.mret || (h0.jump && h0.npc != h0.pnpc);
    rob_out.commit_ctrl = init_commit;
    rob_out.commit0     = 1'b0;
    rob_out.commit1     = 1'b0;
    if (h0_done) begin
      rob_out.commit0 = 1'b1;
      if (h1_done && !h0_flush &&
          !h0.store && !h0.fence && !h0.mret &&
          !h0.wfi && !h0.ecall && !h0.ebreak && !h0.csreg) begin
        rob_out.commit1 = 1'b1;
      end
    end
    rob_out.head_ptr     = r.head;
    rob_out.tail_ptr     = r.tail_ptr;
    rob_out.alloc_tag0   = r.tail_ptr;
    rob_out.alloc_tag1   = r.tail_ptr + 1'b1;
    rob_out.full         = (r.count >= ROB_DEPTH - 1);
    rob_out.has_two_free = (r.count <= ROB_DEPTH - 2);
    rob_out.stall        = (r.count >= ROB_DEPTH - 1);
    rob_out.entry0       = h0;
    rob_out.entry1       = h1;
  end

  always_comb begin
    v = r;

    if (flush) begin
      v = init_rob_reg;
    end else begin
      if (rob_out.commit0) begin
        v.head  = v.head + 1'b1;
        v.count = v.count - 1'b1;
      end
      if (rob_out.commit1) begin
        v.head  = v.head + 1'b1;
        v.count = v.count - 1'b1;
      end
      if (rob_in.alloc0 && v.count < ROB_DEPTH) begin
        v.tail_ptr = v.tail_ptr + 1'b1;
        v.count    = v.count + 1'b1;
      end
      if (rob_in.alloc1 && v.count < ROB_DEPTH) begin
        v.tail_ptr = v.tail_ptr + 1'b1;
        v.count    = v.count + 1'b1;
      end
    end

    rin = v;
  end

  always_ff @(posedge clock) begin
    logic alloc0_ok, alloc1_ok;
    if (reset == 0) begin
      r <= init_rob_reg;
    end else begin
      r <= rin;
      if (flush) begin
        for (int i = 0; i < ROB_DEPTH; i++) begin
          array[i].valid <= 1'b0;
          array[i].done  <= 1'b0;
        end
      end else begin
        alloc0_ok = rob_in.alloc0 && (r.count - rob_out.commit0 - rob_out.commit1 < ROB_DEPTH);
        alloc1_ok = rob_in.alloc1 && (r.count - rob_out.commit0 - rob_out.commit1 + alloc0_ok < ROB_DEPTH);

        if (rob_out.commit0) array[r.head].valid <= 1'b0;
        if (rob_out.commit1) array[r.head+rob_out.commit0].valid <= 1'b0;

        if (alloc0_ok) array[r.tail_ptr] <= rob_in.alloc_entry0;
        if (alloc1_ok) array[r.tail_ptr+alloc0_ok] <= rob_in.alloc_entry1;

        if (rob_in.write_en0) begin
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
        if (rob_in.write_en1) begin
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
        if (rob_in.write_en2) begin
          array[rob_in.write_tag2].done      <= 1'b1;
          array[rob_in.write_tag2].result    <= rob_in.write_entry2.result;
          array[rob_in.write_tag2].exception <= rob_in.write_entry2.exception;
          array[rob_in.write_tag2].ecause    <= rob_in.write_entry2.ecause;
          array[rob_in.write_tag2].etval     <= rob_in.write_entry2.etval;
        end
      end
    end
  end
endmodule
