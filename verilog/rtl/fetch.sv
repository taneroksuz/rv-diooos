import constants::*;
import functions::*;
import wires::*;

module fetch (
  input  logic          reset,
  input  logic          clock,
  input  logic          flush,
  input  logic          stall,
  input  fetch_in_type  fetch_in,
  output fetch_out_type fetch_out
);
  timeunit 1ns; timeprecision 1ps;

  fetch_reg_type r, rin;
  fetch_reg_type v;

  always_comb begin

    v       = r;

    v.valid = 0;
    v.stall = fetch_in.buffer_out.stall;

    v.flush = fetch_in.btac_out.pred_miss0 | fetch_in.btac_out.pred_miss1;
    v.flush = v.flush | fetch_in.btac_out.pred0.taken | fetch_in.btac_out.pred1.taken;
    v.flush = v.flush | fetch_in.csr_out.trap | fetch_in.csr_out.mret;

    if (fetch_in.imem0_out.mem_ready == 1) begin
      v.irdata0 = fetch_in.imem0_out.mem_rdata;
      v.iready0 = fetch_in.imem0_out.mem_ready;
    end

    if (fetch_in.imem1_out.mem_ready == 1) begin
      v.irdata1 = fetch_in.imem1_out.mem_rdata;
      v.iready1 = fetch_in.imem1_out.mem_ready;
    end

    if ((v.iready0 & v.iready1) == 1) begin
      v.rdata   = {v.irdata1, v.irdata0};
      v.ready   = 1;
      v.iready0 = 0;
      v.iready1 = 0;
    end else begin
      v.rdata = 0;
      v.ready = 0;
    end

    v.pc0    = fetch_in.buffer_out.pc0;
    v.pc1    = fetch_in.buffer_out.pc1;
    v.instr0 = fetch_in.buffer_out.instr0;
    v.instr1 = fetch_in.buffer_out.instr1;
    v.ready0 = fetch_in.buffer_out.ready0;
    v.ready1 = fetch_in.buffer_out.ready1;

    if (stall == 1 && flush == 0) begin
      v.pc0    = r.pc0;
      v.pc1    = r.pc1;
      v.instr0 = r.instr0;
      v.instr1 = r.instr1;
      v.ready0 = r.ready0;
      v.ready1 = r.ready1;
    end

    case (v.state)
      IDLE: begin
        v.stall = 1;
      end
      BUSY: begin
        if (v.ready == 0) begin
          v.stall = 1;
        end
      end
      INVALID: begin
        v.stall = 1;
      end
      default: begin
      end
    endcase

    if (fetch_in.csr_out.trap == 1) begin
      v.ipc0 = fetch_in.csr_out.mtvec;
    end else if (fetch_in.csr_out.mret == 1) begin
      v.ipc0 = fetch_in.csr_out.mepc;
    end else if (fetch_in.btac_out.pred_miss0) begin
      v.ipc0 = fetch_in.btac_out.pred_maddr0;
    end else if (fetch_in.btac_out.pred_miss1) begin
      v.ipc0 = fetch_in.btac_out.pred_maddr1;
    end else if (fetch_in.btac_out.pred0.taken) begin
      v.ipc0 = fetch_in.btac_out.pred0.taddr;
    end else if (fetch_in.btac_out.pred1.taken) begin
      v.ipc0 = fetch_in.btac_out.pred1.taddr;
    end else if (v.stall == 0) begin
      v.ipc0 = v.ipc0 + 8;
    end

    v.ipc1 = v.ipc0 + 4;

    case (v.state)
      IDLE: begin
        v.state = BUSY;
        v.valid = 1;
      end
      BUSY: begin
        if (v.ready == 1) begin
          v.state = BUSY;
          v.valid = 1;
        end else if (v.flush == 1) begin
          v.state = INVALID;
          v.valid = 0;
        end else begin
          v.state = BUSY;
          v.valid = 0;
        end
      end
      INVALID: begin
        if (v.ready == 1) begin
          v.state = BUSY;
          v.valid = 1;
        end else begin
          v.state = INVALID;
          v.valid = 0;
        end
        v.ready = 0;
      end
      default: begin
      end
    endcase

    fetch_out.buffer_in.pc0      = r.ipc0;
    fetch_out.buffer_in.pc1      = r.ipc1;
    fetch_out.buffer_in.rdata    = v.rdata;
    fetch_out.buffer_in.ready    = v.ready;
    fetch_out.buffer_in.clear    = v.flush;
    fetch_out.buffer_in.stall    = stall;

    fetch_out.imem0_in.mem_valid = v.valid;
    fetch_out.imem0_in.mem_instr = 1;
    fetch_out.imem0_in.mem_mode  = 0;
    fetch_out.imem0_in.mem_addr  = v.ipc0;
    fetch_out.imem0_in.mem_wdata = 0;
    fetch_out.imem0_in.mem_wstrb = 0;

    fetch_out.imem1_in.mem_valid = v.valid;
    fetch_out.imem1_in.mem_instr = 1;
    fetch_out.imem1_in.mem_mode  = 0;
    fetch_out.imem1_in.mem_addr  = v.ipc1;
    fetch_out.imem1_in.mem_wdata = 0;
    fetch_out.imem1_in.mem_wstrb = 0;

    fetch_out.btac_in.get_pc0    = v.pc0;
    fetch_out.btac_in.get_pc1    = v.pc1;
    fetch_out.btac_in.upd_pc0    = fetch_in.entry0.pc;
    fetch_out.btac_in.upd_pc1    = fetch_in.entry1.pc;
    fetch_out.btac_in.upd_npc0   = fetch_in.entry0.pnpc;
    fetch_out.btac_in.upd_npc1   = fetch_in.entry1.pnpc;
    fetch_out.btac_in.upd_addr0  = fetch_in.entry0.npc;
    fetch_out.btac_in.upd_addr1  = fetch_in.entry1.npc;
    fetch_out.btac_in.upd_jump0  = fetch_in.entry0.jump;
    fetch_out.btac_in.upd_jump1  = fetch_in.entry1.jump;
    fetch_out.btac_in.upd_valid0 = fetch_in.entry0.valid;
    fetch_out.btac_in.upd_valid1 = fetch_in.entry1.valid;
    fetch_out.btac_in.upd_pred0  = fetch_in.entry0.pred;
    fetch_out.btac_in.upd_pred1  = fetch_in.entry1.pred;

    fetch_out.pc0                = v.pc0;
    fetch_out.pc1                = v.pc1;
    fetch_out.instr0             = v.instr0;
    fetch_out.instr1             = v.instr1;
    fetch_out.ready0             = v.ready0;
    fetch_out.ready1             = v.ready1;

    rin                          = v;

  end

  always_ff @(posedge clock) begin
    if (reset == 0) begin
      r <= init_fetch_reg;
    end else begin
      r <= rin;
    end
  end

endmodule
