import configure::*;
import wires::*;

module prf (
    input  logic        reset,
    input  logic        clock,
    input  prf_in_type  prf_in,
    output prf_out_type prf_out,
    input  logic        flush
);
  timeunit 1ns; timeprecision 1ps;

  prf_reg_type r, rin;
  prf_reg_type v;

  function automatic logic [31:0] slot_data(input prf_arr_type arr,
                                            input logic [PRF_ADDR_BITS-1:0] idx);
    return arr[idx*PRF_SLOT_W+:32];
  endfunction

  function automatic logic slot_valid(input prf_arr_type arr, input logic [PRF_ADDR_BITS-1:0] idx);
    return arr[idx*PRF_SLOT_W+32];
  endfunction

  function automatic prf_arr_type slot_write(input prf_arr_type arr,
                                             input logic [PRF_ADDR_BITS-1:0] idx,
                                             input logic [31:0] data, input logic valid);
    prf_arr_type t;
    t                     = arr;
    t[idx*PRF_SLOT_W+:32] = data;
    t[idx*PRF_SLOT_W+32]  = valid;
    return t;
  endfunction

  always_comb begin
    v = r;

    if (prf_in.wren0 && prf_in.waddr0 != 0)
      v.array = slot_write(v.array, prf_in.waddr0, prf_in.wdata0, 1'b1);
    if (prf_in.wren1 && prf_in.waddr1 != 0)
      v.array = slot_write(v.array, prf_in.waddr1, prf_in.wdata1, 1'b1);

    prf_out.rdata0 = slot_data(r.array, prf_in.raddr0);
    prf_out.rvalid0 = slot_valid(r.array, prf_in.raddr0);
    prf_out.rdata1 = slot_data(r.array, prf_in.raddr1);
    prf_out.rvalid1 = slot_valid(r.array, prf_in.raddr1);
    prf_out.rdata2 = slot_data(r.array, prf_in.raddr2);
    prf_out.rvalid2 = slot_valid(r.array, prf_in.raddr2);
    prf_out.rdata3 = slot_data(r.array, prf_in.raddr3);
    prf_out.rvalid3 = slot_valid(r.array, prf_in.raddr3);

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
