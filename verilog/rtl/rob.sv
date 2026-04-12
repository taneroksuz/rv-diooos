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
  rob_entry_type                     array    [0:ROB_DEPTH-1];
  logic          [ROB_ADDR_BITS-1:0] head;
  logic          [ROB_ADDR_BITS-1:0] tail_ptr;
  logic          [  ROB_ADDR_BITS:0] count;
  rob_entry_type h0, h1;
  logic h0_done, h1_done;
  assign rob_entries = array;
  always_comb begin
    h0                  = array[head];
    h1                  = array[head+1'b1];
    h0_done             = h0.valid && h0.done && (count >= 1);
    h1_done             = h1.valid && h1.done && (count >= 2);
    rob_out.commit_ctrl = init_commit;
    rob_out.commit0     = 1'b0;
    rob_out.commit1     = 1'b0;
    if (h0_done) begin
      rob_out.commit0 = 1'b1;
      if (h0.exception) begin
        rob_out.commit_ctrl.flush    = 1'b1;
        rob_out.commit_ctrl.flush_pc = h0.pc;
      end else if (h0.jump && h0.npc != h0.pnpc) begin
        rob_out.commit_ctrl.flush    = 1'b1;
        rob_out.commit_ctrl.flush_pc = h0.npc;
      end else if (h1_done && !h0.exception &&
                   !h0.jump &&
                   !h0.store && !h0.fence && !h0.mret &&
                   !h0.wfi && !h0.ecall && !h0.ebreak && !h0.csreg &&
                   !h1.jump) begin
        rob_out.commit1 = 1'b1;
        if (h1.exception) begin
          rob_out.commit_ctrl.flush    = 1'b1;
          rob_out.commit_ctrl.flush_pc = h1.pc;
        end else if (h1.jump && h1.npc != h1.pnpc) begin
          rob_out.commit_ctrl.flush    = 1'b1;
          rob_out.commit_ctrl.flush_pc = h1.npc;
        end
      end
    end
    rob_out.head_ptr     = head;
    rob_out.tail_ptr     = tail_ptr;
    rob_out.alloc_tag0   = tail_ptr;
    rob_out.alloc_tag1   = tail_ptr + 1'b1;
    rob_out.full         = (count >= ROB_DEPTH - 1);
    rob_out.has_two_free = (count <= ROB_DEPTH - 2);
    rob_out.stall        = (count >= ROB_DEPTH - 1);
    rob_out.entry0       = h0;
    rob_out.entry1       = h1;
  end
  always_ff @(posedge clock) begin
    integer i;
    logic [ROB_ADDR_BITS:0] nc;
    logic [ROB_ADDR_BITS-1:0] nh;
    logic [ROB_ADDR_BITS-1:0] nt;
    if (reset == 0 || flush) begin
      head     <= '0;
      tail_ptr <= '0;
      count    <= '0;
      for (i = 0; i < ROB_DEPTH; i++) array[i] <= init_rob_entry;
    end else begin
      nc = count;
      nh = head;
      nt = tail_ptr;
      if (rob_out.commit0) begin
        array[nh].valid <= 1'b0;
        nh = nh + 1;
        nc = nc - 1;
      end
      if (rob_out.commit1) begin
        array[nh].valid <= 1'b0;
        nh = nh + 1;
        nc = nc - 1;
      end
      if (rob_in.alloc0 && nc < ROB_DEPTH) begin
        array[nt] <= rob_in.alloc_entry0;
        nt = nt + 1;
        nc = nc + 1;
      end
      if (rob_in.alloc1 && nc < ROB_DEPTH) begin
        array[nt] <= rob_in.alloc_entry1;
        nt = nt + 1;
        nc = nc + 1;
      end
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
      head     <= nh;
      tail_ptr <= nt;
      count    <= nc;
    end
  end
endmodule
