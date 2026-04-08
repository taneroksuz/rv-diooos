import constants::*;
import functions::*;
import wires::*;

module ifetch (
    input logic reset,
    input logic clock,
    input logic flush,
    input ifetch_in_type ifetch_in,
    output ifetch_out_type ifetch_out
);
  timeunit 1ns; timeprecision 1ps;

  ifetch_reg_type r, rin;
  ifetch_reg_type v;

  always_comb begin

    v = r;

    v.valid = 0;
    v.fence = 0;
    v.spec = 0;

    if (ifetch_in.imem0_out.mem_ready == 1) begin
      v.irdata0 = ifetch_in.imem0_out.mem_rdata;
      v.iready0 = ifetch_in.imem0_out.mem_ready;
    end

    if (ifetch_in.imem1_out.mem_ready == 1) begin
      v.irdata1 = ifetch_in.imem1_out.mem_rdata;
      v.iready1 = ifetch_in.imem1_out.mem_ready;
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

    if (flush == 1) begin
      v.fence = 0;
      v.spec  = 1;
      v.ipc0  = 0;
    end else if (ifetch_in.csr_out.trap == 1) begin
      v.fence = 0;
      v.spec  = 1;
      v.ipc0  = ifetch_in.csr_out.mtvec;
    end else if (ifetch_in.csr_out.mret == 1) begin
      v.fence = 0;
      v.spec  = 1;
      v.ipc0  = ifetch_in.csr_out.mepc;
    end else if (ifetch_in.btac_out.pred_miss == 1) begin
      v.fence = 0;
      v.spec  = 1;
      v.ipc0  = ifetch_in.btac_out.pred_maddr;
    end else if (ifetch_in.btac_out.pred0.taken == 1) begin
      v.fence = 0;
      v.spec  = 1;
      v.ipc0  = ifetch_in.btac_out.pred0.taddr;
    end else if (ifetch_in.btac_out.pred1.taken == 1) begin
      v.fence = 0;
      v.spec  = 1;
      v.ipc0  = ifetch_in.btac_out.pred1.taddr;
    end else if (v.stall == 0) begin
      v.fence = 0;
      v.spec  = 0;
      v.ipc0  = v.ipc0 + 8;
    end

    v.ipc1 = v.ipc0 + 4;

    ifetch_out.buffer_in.pc0 = r.ipc0;
    ifetch_out.buffer_in.pc1 = r.ipc1;
    ifetch_out.buffer_in.rdata = v.rdata;
    ifetch_out.buffer_in.ready = v.ready;
    ifetch_out.buffer_in.flush = flush;

    ifetch_out.imem0_in.mem_valid = v.valid;
    ifetch_out.imem0_in.mem_instr = 1;
    ifetch_out.imem0_in.mem_mode = 0;
    ifetch_out.imem0_in.mem_addr = v.ipc0;
    ifetch_out.imem0_in.mem_wdata = 0;
    ifetch_out.imem0_in.mem_wstrb = 0;

    ifetch_out.imem1_in.mem_valid = v.valid;
    ifetch_out.imem1_in.mem_instr = 1;
    ifetch_out.imem1_in.mem_mode = 0;
    ifetch_out.imem1_in.mem_addr = v.ipc1;
    ifetch_out.imem1_in.mem_wdata = 0;
    ifetch_out.imem1_in.mem_wstrb = 0;

    ifetch_out.btac_in.get_pc0 = v.pc0;
    ifetch_out.btac_in.get_pc1 = v.pc1;
    ifetch_out.btac_in.flush = flush;

    rin = v;

  end

  always_ff @(posedge clock) begin
    if (reset == 0 || flush == 1) begin
      r <= init_ifetch_reg;
    end else begin
      r <= rin;
    end
  end

endmodule
