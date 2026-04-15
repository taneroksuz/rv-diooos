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

  (* ramstyle = "M20K, no_rw_check" *) logic [PRF_ADDR_BITS:0] spec[0:ARCH_REGS-1] = '{
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

  (* ramstyle = "M20K, no_rw_check" *) logic [PRF_ADDR_BITS:0] comm[0:ARCH_REGS-1] = '{
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

  logic [PRF_ADDR_BITS:0] eff0, eff1, eff2, eff3, old0, old1;

  always_comb begin
    eff0 = flush ? comm[rat_in.rsrc0_a] : spec[rat_in.rsrc0_a];
    eff1 = flush ? comm[rat_in.rsrc1_a] : spec[rat_in.rsrc1_a];
    eff2 = flush ? comm[rat_in.rsrc2_a] : spec[rat_in.rsrc2_a];
    eff3 = flush ? comm[rat_in.rsrc3_a] : spec[rat_in.rsrc3_a];
    old0 = flush ? comm[rat_in.waddr0_a] : spec[rat_in.waddr0_a];
    old1 = flush ? comm[rat_in.waddr1_a] : spec[rat_in.waddr1_a];

    rat_out = init_rat_out;
    rat_out.old_pdest0 = old0[PRF_ADDR_BITS-1:0];
    rat_out.old_pdest1 = (rat_in.wren0 && (rat_in.waddr0_a == rat_in.waddr1_a)) ? rat_in.waddr0_p : old1[PRF_ADDR_BITS-1:0];

    rat_out.psrc0 = eff0[PRF_ADDR_BITS-1:0];
    rat_out.psrc0_valid = eff0[PRF_ADDR_BITS];
    rat_out.psrc1 = eff1[PRF_ADDR_BITS-1:0];
    rat_out.psrc1_valid = eff1[PRF_ADDR_BITS];

    if (rat_in.wren0 && (rat_in.rsrc2_a == rat_in.waddr0_a) && (rat_in.waddr0_a != 5'h0)) begin
      rat_out.psrc2 = rat_in.waddr0_p;
      rat_out.psrc2_valid = 1'b0;
    end else begin
      rat_out.psrc2 = eff2[PRF_ADDR_BITS-1:0];
      rat_out.psrc2_valid = eff2[PRF_ADDR_BITS];
    end

    if (rat_in.wren0 && (rat_in.rsrc3_a == rat_in.waddr0_a) && (rat_in.waddr0_a != 5'h0)) begin
      rat_out.psrc3 = rat_in.waddr0_p;
      rat_out.psrc3_valid = 1'b0;
    end else begin
      rat_out.psrc3 = eff3[PRF_ADDR_BITS-1:0];
      rat_out.psrc3_valid = eff3[PRF_ADDR_BITS];
    end
  end

  always_ff @(posedge clock) begin
    if (reset != 0) begin
      if (flush) begin
        for (int j = 0; j < ARCH_REGS; j++) begin
          spec[j] <= comm[j];
        end
      end

      if (rat_in.commit_en0 && (rat_in.commit_addr0 != 5'h0)) begin
        comm[rat_in.commit_addr0] <= {1'b1, rat_in.commit_tag0};
        if (flush) begin
          spec[rat_in.commit_addr0] <= {1'b1, rat_in.commit_tag0};
        end else if (spec[rat_in.commit_addr0][PRF_ADDR_BITS-1:0] == rat_in.commit_tag0) begin
          spec[rat_in.commit_addr0] <= {1'b1, rat_in.commit_tag0};
        end
      end

      if (rat_in.commit_en1 && (rat_in.commit_addr1 != 5'h0)) begin
        comm[rat_in.commit_addr1] <= {1'b1, rat_in.commit_tag1};
        if (flush) begin
          spec[rat_in.commit_addr1] <= {1'b1, rat_in.commit_tag1};
        end else if (spec[rat_in.commit_addr1][PRF_ADDR_BITS-1:0] == rat_in.commit_tag1) begin
          spec[rat_in.commit_addr1] <= {1'b1, rat_in.commit_tag1};
        end
      end

      if (rat_in.wren0 && (rat_in.waddr0_a != 5'h0)) begin
        spec[rat_in.waddr0_a] <= {1'b0, rat_in.waddr0_p};
      end
      if (rat_in.wren1 && (rat_in.waddr1_a != 5'h0)) begin
        spec[rat_in.waddr1_a] <= {1'b0, rat_in.waddr1_p};
      end
    end
  end
endmodule
