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

  prf_reg_type r, rin;
  prf_reg_type v;

  always_comb begin

    v = r;

    if (prf_in.wren0 && prf_in.waddr0 != 0)
      v.array = prf_slot_write(v.array, prf_in.waddr0, prf_in.wdata0, 1'b1);
    if (prf_in.wren1 && prf_in.waddr1 != 0)
      v.array = prf_slot_write(v.array, prf_in.waddr1, prf_in.wdata1, 1'b1);

    prf_out.rdata0 = prf_slot_data(r.array, prf_in.raddr0);
    prf_out.rvalid0 = prf_slot_valid(r.array, prf_in.raddr0);
    prf_out.rdata1 = prf_slot_data(r.array, prf_in.raddr1);
    prf_out.rvalid1 = prf_slot_valid(r.array, prf_in.raddr1);
    prf_out.rdata2 = prf_slot_data(r.array, prf_in.raddr2);
    prf_out.rvalid2 = prf_slot_valid(r.array, prf_in.raddr2);
    prf_out.rdata3 = prf_slot_data(r.array, prf_in.raddr3);
    prf_out.rvalid3 = prf_slot_valid(r.array, prf_in.raddr3);

    rin = v;

  end

  always_ff @(posedge clock) begin
    if (reset == 0 || flush == 1) begin
      r <= init_prf_reg;
    end else begin
      r <= rin;
    end
  end

endmodule
