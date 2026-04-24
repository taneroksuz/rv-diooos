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

  typedef struct packed {logic [PRF_DEPTH-1:0] written_bits;} prf_reg_type;
  localparam prf_reg_type init_prf_reg = '{written_bits: '0};

  logic [31:0] mem[0:PRF_DEPTH-1];
  prf_reg_type r, rin, v;

  logic wen0, wen1;
  logic [PRF_ADDR_BITS-1:0] waddr0, waddr1;
  logic [31:0] wdata0, wdata1;

  always_comb begin
    v = r;
    wen0 = prf_in.wren0 && (prf_in.waddr0 != '0);
    waddr0 = prf_in.waddr0;
    wdata0 = prf_in.wdata0;
    wen1 = prf_in.wren1 && (prf_in.waddr1 != '0);
    waddr1 = prf_in.waddr1;
    wdata1 = prf_in.wdata1;

    prf_out = init_prf_out;

    prf_out.rdata0 = r.written_bits[prf_in.raddr0] ? mem[prf_in.raddr0] : 32'h0;
    if (wen0 && waddr0 == prf_in.raddr0) prf_out.rdata0 = wdata0;
    else if (wen1 && waddr1 == prf_in.raddr0) prf_out.rdata0 = wdata1;
    prf_out.rvalid0 = 1'b1;

    prf_out.rdata1  = r.written_bits[prf_in.raddr1] ? mem[prf_in.raddr1] : 32'h0;
    if (wen0 && waddr0 == prf_in.raddr1) prf_out.rdata1 = wdata0;
    else if (wen1 && waddr1 == prf_in.raddr1) prf_out.rdata1 = wdata1;
    prf_out.rvalid1 = 1'b1;

    prf_out.rdata2  = r.written_bits[prf_in.raddr2] ? mem[prf_in.raddr2] : 32'h0;
    if (wen0 && waddr0 == prf_in.raddr2) prf_out.rdata2 = wdata0;
    else if (wen1 && waddr1 == prf_in.raddr2) prf_out.rdata2 = wdata1;
    prf_out.rvalid2 = 1'b1;

    prf_out.rdata3  = r.written_bits[prf_in.raddr3] ? mem[prf_in.raddr3] : 32'h0;
    if (wen0 && waddr0 == prf_in.raddr3) prf_out.rdata3 = wdata0;
    else if (wen1 && waddr1 == prf_in.raddr3) prf_out.rdata3 = wdata1;
    prf_out.rvalid3 = 1'b1;

    if (wen0) begin
      v.written_bits[waddr0] = 1'b1;
    end
    if (wen1) begin
      v.written_bits[waddr1] = 1'b1;
    end

    rin = v;
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
      if (wen0) begin
        mem[waddr0] <= wdata0;
      end
      if (wen1) begin
        mem[waddr1] <= wdata1;
      end
    end
  end
endmodule
