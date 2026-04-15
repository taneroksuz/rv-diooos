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

  typedef struct packed {
    logic [0:0]               do_flush;
    logic [4:0]               commit_addr0;
    logic [PRF_ADDR_BITS-1:0] commit_tag0;
    logic [0:0]               commit_en0;
    logic [4:0]               commit_addr1;
    logic [PRF_ADDR_BITS-1:0] commit_tag1;
    logic [0:0]               commit_en1;
    logic [4:0]               waddr0_a;
    logic [PRF_ADDR_BITS-1:0] waddr0_p;
    logic [0:0]               wren0;
    logic [4:0]               waddr1_a;
    logic [PRF_ADDR_BITS-1:0] waddr1_p;
    logic [0:0]               wren1;
    rat_out_type              rat_out;
  } rat_reg_type;

  localparam rat_reg_type init_rat_reg = '{
      do_flush   : 1'b0,
      commit_addr0: '0,
      commit_tag0 : '0,
      commit_en0  : 1'b0,
      commit_addr1: '0,
      commit_tag1 : '0,
      commit_en1  : 1'b0,
      waddr0_a    : '0,
      waddr0_p    : '0,
      wren0       : 1'b0,
      waddr1_a    : '0,
      waddr1_p    : '0,
      wren1       : 1'b0,
      rat_out     : init_rat_out
  };

  logic [PRF_ADDR_BITS:0] spec[0:ARCH_REGS-1] = '{
      0: {1'b1, PRF_ADDR_BITS'(0)},
      1: {1'b1, PRF_ADDR_BITS'(1)},
      2: {1'b1, PRF_ADDR_BITS'(2)},
      3: {1'b1, PRF_ADDR_BITS'(3)},
      4: {1'b1, PRF_ADDR_BITS'(4)},
      5: {1'b1, PRF_ADDR_BITS'(5)},
      6: {1'b1, PRF_ADDR_BITS'(6)},
      7: {1'b1, PRF_ADDR_BITS'(7)},
      8: {1'b1, PRF_ADDR_BITS'(8)},
      9: {1'b1, PRF_ADDR_BITS'(9)},
      10: {1'b1, PRF_ADDR_BITS'(10)},
      11: {1'b1, PRF_ADDR_BITS'(11)},
      12: {1'b1, PRF_ADDR_BITS'(12)},
      13: {1'b1, PRF_ADDR_BITS'(13)},
      14: {1'b1, PRF_ADDR_BITS'(14)},
      15: {1'b1, PRF_ADDR_BITS'(15)},
      16: {1'b1, PRF_ADDR_BITS'(16)},
      17: {1'b1, PRF_ADDR_BITS'(17)},
      18: {1'b1, PRF_ADDR_BITS'(18)},
      19: {1'b1, PRF_ADDR_BITS'(19)},
      20: {1'b1, PRF_ADDR_BITS'(20)},
      21: {1'b1, PRF_ADDR_BITS'(21)},
      22: {1'b1, PRF_ADDR_BITS'(22)},
      23: {1'b1, PRF_ADDR_BITS'(23)},
      24: {1'b1, PRF_ADDR_BITS'(24)},
      25: {1'b1, PRF_ADDR_BITS'(25)},
      26: {1'b1, PRF_ADDR_BITS'(26)},
      27: {1'b1, PRF_ADDR_BITS'(27)},
      28: {1'b1, PRF_ADDR_BITS'(28)},
      29: {1'b1, PRF_ADDR_BITS'(29)},
      30: {1'b1, PRF_ADDR_BITS'(30)},
      31: {1'b1, PRF_ADDR_BITS'(31)}
  };

  logic [PRF_ADDR_BITS:0] comm[0:ARCH_REGS-1] = '{
      0: {1'b1, PRF_ADDR_BITS'(0)},
      1: {1'b1, PRF_ADDR_BITS'(1)},
      2: {1'b1, PRF_ADDR_BITS'(2)},
      3: {1'b1, PRF_ADDR_BITS'(3)},
      4: {1'b1, PRF_ADDR_BITS'(4)},
      5: {1'b1, PRF_ADDR_BITS'(5)},
      6: {1'b1, PRF_ADDR_BITS'(6)},
      7: {1'b1, PRF_ADDR_BITS'(7)},
      8: {1'b1, PRF_ADDR_BITS'(8)},
      9: {1'b1, PRF_ADDR_BITS'(9)},
      10: {1'b1, PRF_ADDR_BITS'(10)},
      11: {1'b1, PRF_ADDR_BITS'(11)},
      12: {1'b1, PRF_ADDR_BITS'(12)},
      13: {1'b1, PRF_ADDR_BITS'(13)},
      14: {1'b1, PRF_ADDR_BITS'(14)},
      15: {1'b1, PRF_ADDR_BITS'(15)},
      16: {1'b1, PRF_ADDR_BITS'(16)},
      17: {1'b1, PRF_ADDR_BITS'(17)},
      18: {1'b1, PRF_ADDR_BITS'(18)},
      19: {1'b1, PRF_ADDR_BITS'(19)},
      20: {1'b1, PRF_ADDR_BITS'(20)},
      21: {1'b1, PRF_ADDR_BITS'(21)},
      22: {1'b1, PRF_ADDR_BITS'(22)},
      23: {1'b1, PRF_ADDR_BITS'(23)},
      24: {1'b1, PRF_ADDR_BITS'(24)},
      25: {1'b1, PRF_ADDR_BITS'(25)},
      26: {1'b1, PRF_ADDR_BITS'(26)},
      27: {1'b1, PRF_ADDR_BITS'(27)},
      28: {1'b1, PRF_ADDR_BITS'(28)},
      29: {1'b1, PRF_ADDR_BITS'(29)},
      30: {1'b1, PRF_ADDR_BITS'(30)},
      31: {1'b1, PRF_ADDR_BITS'(31)}
  };

  rat_reg_type r, rin, v;
  logic [PRF_ADDR_BITS:0] eff0, eff1, eff2, eff3, old0, old1;

  always_comb begin
    v                    = init_rat_reg;

    v.do_flush           = flush;
    v.commit_addr0       = rat_in.commit_addr0;
    v.commit_tag0        = rat_in.commit_tag0;
    v.commit_en0         = rat_in.commit_en0;
    v.commit_addr1       = rat_in.commit_addr1;
    v.commit_tag1        = rat_in.commit_tag1;
    v.commit_en1         = rat_in.commit_en1;
    v.waddr0_a           = rat_in.waddr0_a;
    v.waddr0_p           = rat_in.waddr0_p;
    v.wren0              = rat_in.wren0;
    v.waddr1_a           = rat_in.waddr1_a;
    v.waddr1_p           = rat_in.waddr1_p;
    v.wren1              = rat_in.wren1;

    eff0                 = flush ? comm[rat_in.rsrc0_a] : spec[rat_in.rsrc0_a];
    eff1                 = flush ? comm[rat_in.rsrc1_a] : spec[rat_in.rsrc1_a];
    eff2                 = flush ? comm[rat_in.rsrc2_a] : spec[rat_in.rsrc2_a];
    eff3                 = flush ? comm[rat_in.rsrc3_a] : spec[rat_in.rsrc3_a];
    old0                 = flush ? comm[rat_in.waddr0_a] : spec[rat_in.waddr0_a];
    old1                 = flush ? comm[rat_in.waddr1_a] : spec[rat_in.waddr1_a];

    v.rat_out            = init_rat_out;
    v.rat_out.old_pdest0 = old0[PRF_ADDR_BITS-1:0];
    if (rat_in.wren0 && (rat_in.waddr0_a == rat_in.waddr1_a)) begin
      v.rat_out.old_pdest1 = rat_in.waddr0_p;
    end else begin
      v.rat_out.old_pdest1 = old1[PRF_ADDR_BITS-1:0];
    end

    v.rat_out.psrc0 = eff0[PRF_ADDR_BITS-1:0];
    v.rat_out.psrc0_valid = eff0[PRF_ADDR_BITS];
    v.rat_out.psrc1 = eff1[PRF_ADDR_BITS-1:0];
    v.rat_out.psrc1_valid = eff1[PRF_ADDR_BITS];

    if (rat_in.wren0 && (rat_in.rsrc2_a == rat_in.waddr0_a) && (rat_in.waddr0_a != 5'h0)) begin
      v.rat_out.psrc2 = rat_in.waddr0_p;
      v.rat_out.psrc2_valid = 1'b0;
    end else begin
      v.rat_out.psrc2 = eff2[PRF_ADDR_BITS-1:0];
      v.rat_out.psrc2_valid = eff2[PRF_ADDR_BITS];
    end

    if (rat_in.wren0 && (rat_in.rsrc3_a == rat_in.waddr0_a) && (rat_in.waddr0_a != 5'h0)) begin
      v.rat_out.psrc3 = rat_in.waddr0_p;
      v.rat_out.psrc3_valid = 1'b0;
    end else begin
      v.rat_out.psrc3 = eff3[PRF_ADDR_BITS-1:0];
      v.rat_out.psrc3_valid = eff3[PRF_ADDR_BITS];
    end

    rin = v;
    rat_out = rin.rat_out;
  end

  always_ff @(posedge clock) begin
    if (reset == 0) begin
      r <= init_rat_reg;
    end else begin
      r <= rin;
    end
  end

  always_ff @(posedge clock) begin
    if (reset != 0) begin
      if (rin.do_flush) begin
        for (int j = 0; j < ARCH_REGS; j++) begin
          spec[j] <= comm[j];
        end
      end

      if (rin.commit_en0 && (rin.commit_addr0 != 5'h0)) begin
        comm[rin.commit_addr0] <= {1'b1, rin.commit_tag0};
        if (rin.do_flush) begin
          spec[rin.commit_addr0] <= {1'b1, rin.commit_tag0};
        end else if (spec[rin.commit_addr0][PRF_ADDR_BITS-1:0] == rin.commit_tag0) begin
          spec[rin.commit_addr0] <= {1'b1, rin.commit_tag0};
        end
      end

      if (rin.commit_en1 && (rin.commit_addr1 != 5'h0)) begin
        comm[rin.commit_addr1] <= {1'b1, rin.commit_tag1};
        if (rin.do_flush) begin
          spec[rin.commit_addr1] <= {1'b1, rin.commit_tag1};
        end else if (spec[rin.commit_addr1][PRF_ADDR_BITS-1:0] == rin.commit_tag1) begin
          spec[rin.commit_addr1] <= {1'b1, rin.commit_tag1};
        end
      end

      if (rin.wren0 && (rin.waddr0_a != 5'h0)) begin
        spec[rin.waddr0_a] <= {1'b0, rin.waddr0_p};
      end
      if (rin.wren1 && (rin.waddr1_a != 5'h0)) begin
        spec[rin.waddr1_a] <= {1'b0, rin.waddr1_p};
      end
    end
  end
endmodule
