import configure::*;
import wires::*;

module rat (
    input  logic        reset,
    input  logic        clock,
    input  logic        flush,
    input  rat_in_type  rat_in,
    output rat_out_type rat_out
);
  timeunit 1ns; timeprecision 1ps;

  rat_reg_type r, rin;
  rat_reg_type v;

  function automatic logic [PRF_ADDR_BITS-1:0] rat_tag(input rat_arr_type arr,
                                                       input logic [4:0] idx);
    return arr[idx*RAT_SLOT_W+:PRF_ADDR_BITS];
  endfunction

  function automatic logic rat_valid(input rat_arr_type arr, input logic [4:0] idx);
    return arr[idx*RAT_SLOT_W+PRF_ADDR_BITS];
  endfunction

  function automatic rat_arr_type rat_write(input rat_arr_type arr, input logic [4:0] idx,
                                            input logic [PRF_ADDR_BITS-1:0] tag, input logic valid);
    rat_arr_type t;
    t = arr;
    t[idx*RAT_SLOT_W+:PRF_ADDR_BITS] = tag;
    t[idx*RAT_SLOT_W+PRF_ADDR_BITS] = valid;
    return t;
  endfunction

  function automatic logic [PRF_ADDR_BITS-1:0] lookup_tag(
      input rat_arr_type arr, input logic [4:0] src_a, input logic [4:0] wa0,
      input logic [PRF_ADDR_BITS-1:0] wp0, input logic we0, input logic [4:0] wa1,
      input logic [PRF_ADDR_BITS-1:0] wp1, input logic we1);
    if (we0 && src_a == wa0 && wa0 != 5'h0) return wp0;
    else if (we1 && src_a == wa1 && wa1 != 5'h0) return wp1;
    else return rat_tag(arr, src_a);
  endfunction

  function automatic logic lookup_valid(input rat_arr_type arr, input logic [4:0] src_a,
                                        input logic [4:0] wa0, input logic [PRF_ADDR_BITS-1:0] wp0,
                                        input logic we0, input logic [4:0] wa1,
                                        input logic [PRF_ADDR_BITS-1:0] wp1, input logic we1);
    if (we0 && src_a == wa0 && wa0 != 5'h0) return 1'b0;
    else if (we1 && src_a == wa1 && wa1 != 5'h0) return 1'b0;
    else return rat_valid(arr, src_a);
  endfunction

  always_comb begin
    v = r;

    if (rat_in.wren0 && rat_in.waddr0_a != 5'h0)
      v.spec = rat_write(v.spec, rat_in.waddr0_a, rat_in.waddr0_p, 1'b0);
    if (rat_in.wren1 && rat_in.waddr1_a != 5'h0)
      v.spec = rat_write(v.spec, rat_in.waddr1_a, rat_in.waddr1_p, 1'b0);

    if (rat_in.commit_en0 && rat_in.commit_addr0 != 5'h0) begin
      v.comm = rat_write(v.comm, rat_in.commit_addr0, rat_in.commit_tag0, 1'b1);

      if (rat_tag(v.spec, rat_in.commit_addr0) == rat_in.commit_tag0)
        v.spec = rat_write(v.spec, rat_in.commit_addr0, rat_in.commit_tag0, 1'b1);
    end
    if (rat_in.commit_en1 && rat_in.commit_addr1 != 5'h0) begin
      v.comm = rat_write(v.comm, rat_in.commit_addr1, rat_in.commit_tag1, 1'b1);
      if (rat_tag(v.spec, rat_in.commit_addr1) == rat_in.commit_tag1)
        v.spec = rat_write(v.spec, rat_in.commit_addr1, rat_in.commit_tag1, 1'b1);
    end

    rat_out.old_pdest0 = rat_tag(r.spec, rat_in.waddr0_a);
    rat_out.old_pdest1 = (rat_in.wren0 && rat_in.waddr0_a == rat_in.waddr1_a) ?
                          rat_in.waddr0_p : rat_tag(r.spec, rat_in.waddr1_a);

    rat_out.psrc0 = rat_tag(r.spec, rat_in.rsrc0_a);
    rat_out.psrc0_valid = rat_valid(r.spec, rat_in.rsrc0_a);
    rat_out.psrc1 = rat_tag(r.spec, rat_in.rsrc1_a);
    rat_out.psrc1_valid = rat_valid(r.spec, rat_in.rsrc1_a);

    rat_out.psrc2 = lookup_tag(r.spec, rat_in.rsrc2_a, rat_in.waddr0_a, rat_in.waddr0_p,
                               rat_in.wren0, 5'h0, '0, 1'b0);
    rat_out.psrc2_valid = lookup_valid(r.spec, rat_in.rsrc2_a, rat_in.waddr0_a, rat_in.waddr0_p,
                                       rat_in.wren0, 5'h0, '0, 1'b0);
    rat_out.psrc3 = lookup_tag(r.spec, rat_in.rsrc3_a, rat_in.waddr0_a, rat_in.waddr0_p,
                               rat_in.wren0, 5'h0, '0, 1'b0);
    rat_out.psrc3_valid = lookup_valid(r.spec, rat_in.rsrc3_a, rat_in.waddr0_a, rat_in.waddr0_p,
                                       rat_in.wren0, 5'h0, '0, 1'b0);

    rin = v;
  end

  always_ff @(posedge clock) begin
    if (reset == 0) begin
      rat_reg_type init_v;
      integer i;
      for (i = 0; i < ARCH_REGS; i++) begin
        init_v.spec[i*RAT_SLOT_W+:PRF_ADDR_BITS] = PRF_ADDR_BITS'(i);
        init_v.spec[i*RAT_SLOT_W+PRF_ADDR_BITS]  = 1'b1;
        init_v.comm[i*RAT_SLOT_W+:PRF_ADDR_BITS] = PRF_ADDR_BITS'(i);
        init_v.comm[i*RAT_SLOT_W+PRF_ADDR_BITS]  = 1'b1;
      end
      r <= init_v;
    end else if (flush) begin
      r.spec <= r.comm;
    end else begin
      r <= rin;
    end
  end

endmodule
