import constants::*;
import functions::*;
import wires::*;

module ifetch (
    input logic reset,
    input logic clock,
    input logic flush,
    input logic [31:0] flush_pc,
    input ifetch_in_type ifetch_in,
    output ifetch_out_type ifetch_out
);
  timeunit 1ns; timeprecision 1ps;

  ifetch_reg_type r, rin;
  ifetch_reg_type v;

  always_comb begin

    v = r;

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

    case (r.state)
      IDLE: begin
        v.valid = 1;
        v.stall = 0;
        if (v.ready == 0) begin
          v.state = BUSY;
          v.stall = 1;
        end
      end
      BUSY: begin
        v.valid = 0;
        v.stall = 1;
        if (flush == 1) begin
          v.state = INVALID;
          v.stall = 1;
        end
        if (v.ready == 1) begin
          v.state = IDLE;
          v.stall = 0;
        end
      end
      INVALID: begin
        v.valid = 0;
        v.stall = 1;
        if (v.ready == 1) begin
          v.state = IDLE;
          v.stall = 1;
        end
      end
      default: begin
        v.valid = 0;
        v.stall = 1;
      end
    endcase

    if (flush == 1) begin
      v.ipc0 = flush_pc;
    end else if (v.stall == 0) begin
      v.ipc0 = v.ipc0 + 8;
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

    rin = v;

  end

  always_ff @(posedge clock) begin
    if (reset == 0) begin
      r <= init_ifetch_reg;
    end else begin
      r <= rin;
    end
  end

endmodule
