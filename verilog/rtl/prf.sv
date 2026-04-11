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
  logic [32:0] mem[0:PRF_DEPTH-1];
  always_ff @(posedge clock) begin
    if (reset == 0) begin
      integer k;
      for (k = 0; k < PRF_DEPTH; k++) mem[k] <= 33'b1_00000000000000000000000000000000;
    end else begin
      if (prf_in.wren0 && prf_in.waddr0 != '0) mem[prf_in.waddr0] <= {1'b1, prf_in.wdata0};
      if (prf_in.wren1 && prf_in.waddr1 != '0) mem[prf_in.waddr1] <= {1'b1, prf_in.wdata1};
    end
  end
  assign prf_out.rdata0  = mem[prf_in.raddr0][31:0];
  assign prf_out.rvalid0 = mem[prf_in.raddr0][32];
  assign prf_out.rdata1  = mem[prf_in.raddr1][31:0];
  assign prf_out.rvalid1 = mem[prf_in.raddr1][32];
  assign prf_out.rdata2  = mem[prf_in.raddr2][31:0];
  assign prf_out.rvalid2 = mem[prf_in.raddr2][32];
  assign prf_out.rdata3  = mem[prf_in.raddr3][31:0];
  assign prf_out.rvalid3 = mem[prf_in.raddr3][32];
endmodule
