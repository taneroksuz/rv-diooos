import configure::*;
import wires::*;
import functions::*;
module prf (
    input  logic        reset,
    input  logic        clock,
    input  logic        flush,
    input  prf_in_type  prf_in,
    output prf_out_type prf_out
);
  timeunit 1ns; timeprecision 1ps;

  typedef struct packed {
    logic                     wen0;
    logic                     wen1;
    logic [PRF_ADDR_BITS-1:0] waddr0;
    logic [PRF_ADDR_BITS-1:0] waddr1;
    logic [31:0]              wdata0;
    logic [31:0]              wdata1;
    logic [PRF_DEPTH-1:0]     written_bits;
    prf_out_type              prf_out;
  } prf_reg_type;

  localparam prf_reg_type init_prf_reg = '{
      wen0: 1'b0,
      wen1: 1'b0,
      waddr0: '0,
      waddr1: '0,
      wdata0: '0,
      wdata1: '0,
      written_bits: '0,
      prf_out: init_prf_out
  };

  logic [31:0] mem[0:PRF_DEPTH-1];
  prf_reg_type r, rin, v;

  always_comb begin
    v = r;
    v.wen0 = prf_in.wren0 && (prf_in.waddr0 != '0) && !flush;
    v.waddr0 = prf_in.waddr0;
    v.wdata0 = prf_in.wdata0;
    v.wen1 = prf_in.wren1 && (prf_in.waddr1 != '0) && !flush;
    v.waddr1 = prf_in.waddr1;
    v.wdata1 = prf_in.wdata1;

    if (v.wen0) begin
      v.written_bits[v.waddr0] = 1'b1;
    end
    if (v.wen1) begin
      v.written_bits[v.waddr1] = 1'b1;
    end

    v.prf_out = init_prf_out;
    if (r.written_bits[prf_in.raddr0]) begin
      v.prf_out.rdata0 = mem[prf_in.raddr0];
    end else begin
      v.prf_out.rdata0 = 32'h0;
    end
    v.prf_out.rvalid0 = 1'b1;

    if (r.written_bits[prf_in.raddr1]) begin
      v.prf_out.rdata1 = mem[prf_in.raddr1];
    end else begin
      v.prf_out.rdata1 = 32'h0;
    end
    v.prf_out.rvalid1 = 1'b1;

    if (r.written_bits[prf_in.raddr2]) begin
      v.prf_out.rdata2 = mem[prf_in.raddr2];
    end else begin
      v.prf_out.rdata2 = 32'h0;
    end
    v.prf_out.rvalid2 = 1'b1;

    if (r.written_bits[prf_in.raddr3]) begin
      v.prf_out.rdata3 = mem[prf_in.raddr3];
    end else begin
      v.prf_out.rdata3 = 32'h0;
    end
    v.prf_out.rvalid3 = 1'b1;

    rin = v;
    prf_out = rin.prf_out;
  end

  always_ff @(posedge clock) begin
    if (reset == 0) begin
      r <= init_prf_reg;
    end else begin
      r <= rin;
    end
  end

  always_ff @(posedge clock) begin
    if (reset != 0) begin
      if (rin.wen0) mem[rin.waddr0] <= rin.wdata0;
      if (rin.wen1) mem[rin.waddr1] <= rin.wdata1;
    end
  end
endmodule
