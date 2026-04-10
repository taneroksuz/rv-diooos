import configure::*;
import constants::*;
import wires::*;
import functions::*;

module rob (
    input  logic        reset,
    input  logic        clock,
    input  logic        flush,
    input  rob_in_type  rob_in,
    output rob_out_type rob_out
);
  timeunit 1ns; timeprecision 1ps;

  rob_reg_type r, rin;
  rob_reg_type v;

  rob_entry_type h0, h1, e, cleared;
  logic h0_done, h1_done;

  always_comb begin

    h0                  = init_rob_entry;
    h1                  = init_rob_entry;
    e                   = init_rob_entry;
    cleared             = init_rob_entry;

    v                   = r;

    h0                  = rob_read(r.array, r.head);
    h1                  = rob_read(r.array, r.head + 1);
    h0_done             = h0.valid && h0.done && r.count >= 1;
    h1_done             = h1.valid && h1.done && r.count >= 2;

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

    if (rob_out.commit0) begin
      cleared       = rob_read(v.array, v.head);
      cleared.valid = 1'b0;
      v.array       = rob_write(v.array, v.head, cleared);
      v.head        = v.head + 1;
      v.count       = v.count - 1;
    end
    if (rob_out.commit1) begin
      cleared       = rob_read(v.array, v.head);
      cleared.valid = 1'b0;
      v.array       = rob_write(v.array, v.head, cleared);
      v.head        = v.head + 1;
      v.count       = v.count - 1;
    end

    if (rob_in.alloc0 && v.count < ROB_DEPTH) begin
      v.array = rob_write(v.array, v.tail, rob_in.alloc_entry0);
      v.tail  = v.tail + 1;
      v.count = v.count + 1;
    end
    if (rob_in.alloc1 && v.count < ROB_DEPTH - 1) begin
      v.array = rob_write(v.array, v.tail, rob_in.alloc_entry1);
      v.tail  = v.tail + 1;
      v.count = v.count + 1;
    end

    if (rob_in.write_en0) begin
      e            = rob_read(v.array, rob_in.write_tag0);
      e.done       = 1'b1;
      e.result     = rob_in.write_entry0.result;
      e.exception  = rob_in.write_entry0.exception;
      e.ecause     = rob_in.write_entry0.ecause;
      e.etval      = rob_in.write_entry0.etval;
      e.npc        = rob_in.write_entry0.npc;
      e.branch     = rob_in.write_entry0.branch;
      e.jump       = rob_in.write_entry0.jump;
      e.store_addr = rob_in.write_entry0.store_addr;
      e.store_data = rob_in.write_entry0.store_data;
      e.store_strb = rob_in.write_entry0.store_strb;
      e.cwdata     = rob_in.write_entry0.cwdata;
      v.array      = rob_write(v.array, rob_in.write_tag0, e);
    end
    if (rob_in.write_en1) begin
      e            = rob_read(v.array, rob_in.write_tag1);
      e.done       = 1'b1;
      e.result     = rob_in.write_entry1.result;
      e.exception  = rob_in.write_entry1.exception;
      e.ecause     = rob_in.write_entry1.ecause;
      e.etval      = rob_in.write_entry1.etval;
      e.npc        = rob_in.write_entry1.npc;
      e.branch     = rob_in.write_entry1.branch;
      e.jump       = rob_in.write_entry1.jump;
      e.store_addr = rob_in.write_entry1.store_addr;
      e.store_data = rob_in.write_entry1.store_data;
      e.store_strb = rob_in.write_entry1.store_strb;
      e.cwdata     = rob_in.write_entry1.cwdata;
      v.array      = rob_write(v.array, rob_in.write_tag1, e);
    end

    if (rob_in.write_en2) begin
      e           = rob_read(v.array, rob_in.write_tag2);
      e.done      = 1'b1;
      e.result    = rob_in.write_entry2.result;
      e.exception = rob_in.write_entry2.exception;
      e.ecause    = rob_in.write_entry2.ecause;
      e.etval     = rob_in.write_entry2.etval;
      v.array     = rob_write(v.array, rob_in.write_tag2, e);
    end

    rob_out.array        = r.array;
    rob_out.head_ptr     = r.head;
    rob_out.tail_ptr     = r.tail;
    rob_out.alloc_tag0   = r.tail;
    rob_out.alloc_tag1   = r.tail + 1;
    rob_out.full         = r.count >= ROB_DEPTH - 1;
    rob_out.has_two_free = r.count <= ROB_DEPTH - 2;
    rob_out.stall        = r.count >= ROB_DEPTH - 1;
    rob_out.entry0       = h0;
    rob_out.entry1       = h1;

    rin                  = v;

  end

  always_ff @(posedge clock) begin
    if (reset == 0) begin
      r <= init_rob_reg;
    end else if (flush) begin
      r <= init_rob_reg;
    end else begin
      r <= rin;
    end
  end

endmodule
