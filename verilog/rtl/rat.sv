import configure::*;
import wires::*;
import functions::*;

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

    rat_out.psrc2 = rat_lookup_tag(r.spec, rat_in.rsrc2_a, rat_in.waddr0_a, rat_in.waddr0_p,
                                   rat_in.wren0, 5'h0, '0, 1'b0);
    rat_out.psrc2_valid = rat_lookup_valid(r.spec, rat_in.rsrc2_a, rat_in.waddr0_a, rat_in.waddr0_p,
                                           rat_in.wren0, 5'h0, '0, 1'b0);
    rat_out.psrc3 = rat_lookup_tag(r.spec, rat_in.rsrc3_a, rat_in.waddr0_a, rat_in.waddr0_p,
                                   rat_in.wren0, 5'h0, '0, 1'b0);
    rat_out.psrc3_valid = rat_lookup_valid(r.spec, rat_in.rsrc3_a, rat_in.waddr0_a, rat_in.waddr0_p,
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
