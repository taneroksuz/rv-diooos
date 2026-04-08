import constants::*;
import functions::*;
import wires::*;

module ifetch (
    input logic reset,
    input logic clock,
    input logic flush,
    input logic halt,
    input buffer_out_type buffer_out,
    output buffer_in_type buffer_in,
    input csr_out_type csr_out,
    input btac_out_type btac_out,
    output btac_in_type btac_in,
    input mem_out_type imem0_out,
    input mem_out_type imem1_out,
    output mem_in_type imem0_in,
    output mem_in_type imem1_in,
    output ifetch_out_type ifetch_out
);
  timeunit 1ns; timeprecision 1ps;

  ifetch_reg_type r, rin;
  ifetch_reg_type v;

  always_comb begin

    v = r;

    v.valid = 0;
    v.stall = buffer_out.stall;

    v.fence = 0;
    v.spec = 0;

    if (imem0_out.mem_ready == 1) begin
      v.irdata0 = imem0_out.mem_rdata;
      v.iready0 = imem0_out.mem_ready;
    end

    if (imem1_out.mem_ready == 1) begin
      v.irdata1 = imem1_out.mem_rdata;
      v.iready1 = imem1_out.mem_ready;
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

    v.pc0 = buffer_out.pc0;
    v.pc1 = buffer_out.pc1;
    v.instr0 = buffer_out.instr0;
    v.instr1 = buffer_out.instr1;
    v.ready0 = buffer_out.ready0;
    v.ready1 = buffer_out.ready1;

    if (flush == 1) begin
      v.fence = 0;
      v.spec  = 1;
      v.ipc0  = 0;
    end else if (csr_out.trap == 1) begin
      v.fence = 0;
      v.spec  = 1;
      v.ipc0  = csr_out.mtvec;
    end else if (csr_out.mret == 1) begin
      v.fence = 0;
      v.spec  = 1;
      v.ipc0  = csr_out.mepc;
    end else if (btac_out.pred_miss == 1) begin
      v.fence = 0;
      v.spec  = 1;
      v.ipc0  = btac_out.pred_maddr;
    end else if (btac_out.pred0.taken == 1) begin
      v.fence = 0;
      v.spec  = 1;
      v.ipc0  = btac_out.pred0.taddr;
    end else if (btac_out.pred1.taken == 1) begin
      v.fence = 0;
      v.spec  = 1;
      v.ipc0  = btac_out.pred1.taddr;
    end else if (v.stall == 0) begin
      v.fence = 0;
      v.spec  = 0;
      v.ipc0  = v.ipc0 + 8;
    end

    v.ipc1 = v.ipc0 + 4;

    buffer_in.pc0 = r.ipc0;
    buffer_in.pc1 = r.ipc1;
    buffer_in.rdata = v.rdata;
    buffer_in.ready = v.ready;
    buffer_in.flush = v.spec;
    buffer_in.stall = halt;

    imem0_in.mem_valid = v.valid;
    imem0_in.mem_instr = 1;
    imem0_in.mem_mode = 0;
    imem0_in.mem_addr = v.ipc0;
    imem0_in.mem_wdata = 0;
    imem0_in.mem_wstrb = 0;

    imem1_in.mem_valid = v.valid;
    imem1_in.mem_instr = 1;
    imem1_in.mem_mode = 0;
    imem1_in.mem_addr = v.ipc1;
    imem1_in.mem_wdata = 0;
    imem1_in.mem_wstrb = 0;

    btac_in.get_pc0 = v.pc0;
    btac_in.get_pc1 = v.pc1;
    btac_in.stall = 0;
    btac_in.flush = flush;

    rin = v;

    ifetch_out.pc0 = r.pc0;
    ifetch_out.pc1 = r.pc1;
    ifetch_out.instr0 = r.instr0;
    ifetch_out.instr1 = r.instr1;
    ifetch_out.ready0 = r.ready0;
    ifetch_out.ready1 = r.ready1;

  end

  always_ff @(posedge clock) begin
    if (reset == 0 || flush == 1) begin
      r <= init_ifetch_reg;
    end else begin
      r <= rin;
    end
  end

endmodule
