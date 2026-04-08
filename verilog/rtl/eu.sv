import configure::*;
import constants::*;
import wires::*;
import functions::*;

module eu (
    input  logic       reset,
    input  logic       clock,
    input  eu_in_type  eu_in,
    output eu_out_type eu_out,
    input  logic       flush
);
  timeunit 1ns; timeprecision 1ps;

  assign eu_out.alu0_in.rdata1 = eu_in.int_issue0.rdata1;
  assign eu_out.alu0_in.rdata2 = eu_in.int_issue0.rdata2;
  assign eu_out.alu0_in.imm    = eu_in.int_issue0.imm;
  assign eu_out.alu0_in.sel    = eu_in.int_issue0.op.rden2;
  assign eu_out.alu0_in.alu_op = eu_in.int_issue0.alu_op;

  assign eu_out.alu1_in.rdata1 = eu_in.int_issue1.rdata1;
  assign eu_out.alu1_in.rdata2 = eu_in.int_issue1.rdata2;
  assign eu_out.alu1_in.imm    = eu_in.int_issue1.imm;
  assign eu_out.alu1_in.sel    = eu_in.int_issue1.op.rden2;
  assign eu_out.alu1_in.alu_op = eu_in.int_issue1.alu_op;

  assign eu_out.agu0_in.rdata1 = eu_in.int_issue0.rdata1;
  assign eu_out.agu0_in.imm    = eu_in.int_issue0.imm;
  assign eu_out.agu0_in.pc     = eu_in.int_issue0.pc;
  assign eu_out.agu0_in.auipc  = eu_in.int_issue0.op.auipc;
  assign eu_out.agu0_in.jal    = eu_in.int_issue0.op.jal;
  assign eu_out.agu0_in.jalr   = eu_in.int_issue0.op.jalr;
  assign eu_out.agu0_in.branch = eu_in.int_issue0.op.branch;
  assign eu_out.agu0_in.load   = 0;
  assign eu_out.agu0_in.store  = 0;
  assign eu_out.agu0_in.lsu_op = init_lsu_op;

  assign eu_out.agu1_in.rdata1 = eu_in.int_issue1.rdata1;
  assign eu_out.agu1_in.imm    = eu_in.int_issue1.imm;
  assign eu_out.agu1_in.pc     = eu_in.int_issue1.pc;
  assign eu_out.agu1_in.auipc  = eu_in.int_issue1.op.auipc;
  assign eu_out.agu1_in.jal    = eu_in.int_issue1.op.jal;
  assign eu_out.agu1_in.jalr   = eu_in.int_issue1.op.jalr;
  assign eu_out.agu1_in.branch = eu_in.int_issue1.op.branch;
  assign eu_out.agu1_in.load   = 0;
  assign eu_out.agu1_in.store  = 0;
  assign eu_out.agu1_in.lsu_op = init_lsu_op;

  assign eu_out.bcu0_in.rdata1 = eu_in.int_issue0.rdata1;
  assign eu_out.bcu0_in.rdata2 = eu_in.int_issue0.rdata2;
  assign eu_out.bcu0_in.enable = eu_in.int_issue0.op.branch;
  assign eu_out.bcu0_in.bcu_op = eu_in.int_issue0.bcu_op;

  assign eu_out.bcu1_in.rdata1 = eu_in.int_issue1.rdata1;
  assign eu_out.bcu1_in.rdata2 = eu_in.int_issue1.rdata2;
  assign eu_out.bcu1_in.enable = eu_in.int_issue1.op.branch;
  assign eu_out.bcu1_in.bcu_op = eu_in.int_issue1.bcu_op;

  logic branch0_taken, branch1_taken;
  assign branch0_taken = eu_in.int_issue0.op.branch & eu_in.bcu0_out.branch;
  assign branch1_taken = eu_in.int_issue1.op.branch & eu_in.bcu1_out.branch;

  assign eu_out.mul_in.rdata1 = eu_in.int_issue0.op.mult ? eu_in.int_issue0.rdata1 : eu_in.int_issue1.rdata1;
  assign eu_out.mul_in.rdata2 = eu_in.int_issue0.op.mult ? eu_in.int_issue0.rdata2 : eu_in.int_issue1.rdata2;
  assign eu_out.mul_in.mul_op = eu_in.int_issue0.op.mult ? eu_in.int_issue0.mul_op : eu_in.int_issue1.mul_op;

  assign eu_out.div_in.rdata1 = eu_in.int_issue0.op.division ? eu_in.int_issue0.rdata1 : eu_in.int_issue1.rdata1;
  assign eu_out.div_in.rdata2 = eu_in.int_issue0.op.division ? eu_in.int_issue0.rdata2 : eu_in.int_issue1.rdata2;
  assign eu_out.div_in.div_op = eu_in.int_issue0.op.division ? eu_in.int_issue0.div_op : eu_in.int_issue1.div_op;
  assign eu_out.div_in.enable = (eu_in.int_issue0.op.division & eu_in.int_issue0_valid) |
                                 (eu_in.int_issue1.op.division & eu_in.int_issue1_valid);

  assign eu_out.bit_alu0_in.rdata1 = eu_in.int_issue0.rdata1;
  assign eu_out.bit_alu0_in.rdata2 = eu_in.int_issue0.rdata2;
  assign eu_out.bit_alu0_in.imm = eu_in.int_issue0.imm;
  assign eu_out.bit_alu0_in.sel = eu_in.int_issue0.op.rden2;
  assign eu_out.bit_alu0_in.bit_op = eu_in.int_issue0.bit_op;

  assign eu_out.bit_alu1_in.rdata1 = eu_in.int_issue1.rdata1;
  assign eu_out.bit_alu1_in.rdata2 = eu_in.int_issue1.rdata2;
  assign eu_out.bit_alu1_in.imm = eu_in.int_issue1.imm;
  assign eu_out.bit_alu1_in.sel = eu_in.int_issue1.op.rden2;
  assign eu_out.bit_alu1_in.bit_op = eu_in.int_issue1.bit_op;

  assign eu_out.bit_clmul_in.rdata1 = eu_in.int_issue0.op.bitc ? eu_in.int_issue0.rdata1 : eu_in.int_issue1.rdata1;
  assign eu_out.bit_clmul_in.rdata2 = eu_in.int_issue0.op.bitc ? eu_in.int_issue0.rdata2 : eu_in.int_issue1.rdata2;
  assign eu_out.bit_clmul_in.enable = (eu_in.int_issue0.op.bitc & eu_in.int_issue0_valid) |
                                       (eu_in.int_issue1.op.bitc & eu_in.int_issue1_valid);
  assign eu_out.bit_clmul_in.op     = eu_in.int_issue0.op.bitc ? eu_in.int_issue0.bit_op.bit_zbc
                                                                 : eu_in.int_issue1.bit_op.bit_zbc;

  assign eu_out.csr_alu_in.cdata = eu_in.csr.cdata;
  assign eu_out.csr_alu_in.rdata1 = eu_in.int_issue0.op.csreg ? eu_in.int_issue0.rdata1 : eu_in.int_issue1.rdata1;
  assign eu_out.csr_alu_in.imm    = eu_in.int_issue0.op.csreg ? eu_in.int_issue0.imm    : eu_in.int_issue1.imm;
  assign eu_out.csr_alu_in.sel    = eu_in.int_issue0.op.csreg ?
    (eu_in.int_issue0.csr_op.csrrwi | eu_in.int_issue0.csr_op.csrrsi | eu_in.int_issue0.csr_op.csrrci) :
    (eu_in.int_issue1.csr_op.csrrwi | eu_in.int_issue1.csr_op.csrrsi | eu_in.int_issue1.csr_op.csrrci);
  assign eu_out.csr_alu_in.csr_op = eu_in.int_issue0.op.csreg ? eu_in.int_issue0.csr_op : eu_in.int_issue1.csr_op;

  function automatic logic [31:0] eu_result(input rs_entry_type e, input logic [31:0] alu_r, agu_r,
                                            mul_r, div_r, bit_r, csr_r, bc_r);
    if (e.op.alunit) return alu_r;
    else if (e.op.lui) return e.imm;
    else if (e.op.auipc) return agu_r;
    else if (e.op.jal) return e.npc;
    else if (e.op.jalr) return e.npc;
    else if (e.op.mult) return mul_r;
    else if (e.op.division) return div_r;
    else if (e.op.bitm) return bit_r;
    else if (e.op.bitc) return bc_r;
    else if (e.op.csreg) return csr_r;
    else return alu_r;
  endfunction

  function automatic logic eu_done(input rs_entry_type e, input logic valid, input div_out_type dv,
                                   input bit_clmul_out_type bc);
    if (!valid) return 0;
    if (e.op.division) return dv.ready;
    if (e.op.bitc) return bc.ready;
    return 1;
  endfunction

  logic [31:0] eu0_result, eu1_result;
  logic eu0_done, eu1_done;

  assign eu0_result = eu_result(
      eu_in.int_issue0,
      eu_in.alu0_out.result,
      eu_in.agu0_out.address,
      eu_in.mul_out.result,
      eu_in.div_out.result,
      eu_in.bit_alu0_out.result,
      eu_in.csr_alu_out.cdata,
      eu_in.bit_clmul_out.result
  );
  assign eu0_done = eu_done(
      eu_in.int_issue0, eu_in.int_issue0_valid, eu_in.div_out, eu_in.bit_clmul_out
  );

  assign eu1_result = eu_result(
      eu_in.int_issue1,
      eu_in.alu1_out.result,
      eu_in.agu1_out.address,
      eu_in.mul_out.result,
      eu_in.div_out.result,
      eu_in.bit_alu1_out.result,
      eu_in.csr_alu_out.cdata,
      eu_in.bit_clmul_out.result
  );
  assign eu1_done = eu_done(
      eu_in.int_issue1, eu_in.int_issue1_valid, eu_in.div_out, eu_in.bit_clmul_out
  );

  agu_in_type  magu_in;
  agu_out_type magu_out;
  assign magu_in.rdata1 = eu_in.mem_issue0.rdata1;
  assign magu_in.imm    = eu_in.mem_issue0.imm;
  assign magu_in.pc     = eu_in.mem_issue0.pc;
  assign magu_in.auipc  = 0;
  assign magu_in.jal    = 0;
  assign magu_in.jalr   = 0;
  assign magu_in.branch = 0;
  assign magu_in.load   = eu_in.mem_issue0.op.load;
  assign magu_in.store  = eu_in.mem_issue0.op.store;
  assign magu_in.lsu_op = eu_in.mem_issue0.lsu_op;
  agu magu_comp (
      .agu_in (magu_in),
      .agu_out(magu_out)
  );

  logic [31:0] mstore_data;
  assign mstore_data = store_data(
      eu_in.mem_issue0.rdata2,
      eu_in.mem_issue0.lsu_op.lsu_sb,
      eu_in.mem_issue0.lsu_op.lsu_sh,
      eu_in.mem_issue0.lsu_op.lsu_sw
  );

  always_comb begin
    eu_out.cdb0 = init_cdb;
    eu_out.cdb1 = init_cdb;
    eu_out.rob_wtag0 = eu_in.int_issue0.rob_tag;
    eu_out.rob_wentry0 = init_rob_entry;
    eu_out.rob_wen0 = 0;
    eu_out.rob_wtag1 = eu_in.int_issue1.rob_tag;
    eu_out.rob_wentry1 = init_rob_entry;
    eu_out.rob_wen1 = 0;

    if (!flush) begin
      if (eu_in.int_issue0_valid && eu0_done) begin
        if (eu_in.int_issue0.op.wren) begin
          eu_out.cdb0.valid = 1;
          eu_out.cdb0.tag   = eu_in.int_issue0.pdest;
          eu_out.cdb0.data  = eu0_result;
        end
        eu_out.rob_wen0 = 1;
        eu_out.rob_wentry0.done = 1;
        eu_out.rob_wentry0.result = eu0_result;
        eu_out.rob_wentry0.npc = eu_in.agu0_out.address;
        eu_out.rob_wentry0.branch = eu_in.int_issue0.op.branch;
        eu_out.rob_wentry0.jump        = eu_in.int_issue0.op.jal | eu_in.int_issue0.op.jalr | branch0_taken;
        eu_out.rob_wentry0.exception   = eu_in.int_issue0.op.ecall | eu_in.int_issue0.op.ebreak | eu_in.agu0_out.exception;
        eu_out.rob_wentry0.ecause      = eu_in.int_issue0.op.ecall  ? except_env_call_user :
                                         eu_in.int_issue0.op.ebreak ? except_breakpoint : eu_in.agu0_out.ecause;
        eu_out.rob_wentry0.etval = eu_in.agu0_out.etval;
        eu_out.rob_wentry0.cwdata = eu_in.csr_alu_out.cdata;
      end

      if (eu_in.int_issue1_valid && eu1_done) begin
        if (eu_in.int_issue1.op.wren) begin
          eu_out.cdb1.valid = 1;
          eu_out.cdb1.tag   = eu_in.int_issue1.pdest;
          eu_out.cdb1.data  = eu1_result;
        end
        eu_out.rob_wen1 = 1;
        eu_out.rob_wentry1.done = 1;
        eu_out.rob_wentry1.result = eu1_result;
        eu_out.rob_wentry1.npc = eu_in.agu1_out.address;
        eu_out.rob_wentry1.branch = eu_in.int_issue1.op.branch;
        eu_out.rob_wentry1.jump        = eu_in.int_issue1.op.jal | eu_in.int_issue1.op.jalr | branch1_taken;
        eu_out.rob_wentry1.exception   = eu_in.int_issue1.op.ecall | eu_in.int_issue1.op.ebreak | eu_in.agu1_out.exception;
        eu_out.rob_wentry1.ecause      = eu_in.int_issue1.op.ecall  ? except_env_call_user :
                                         eu_in.int_issue1.op.ebreak ? except_breakpoint : eu_in.agu1_out.ecause;
        eu_out.rob_wentry1.etval = eu_in.agu1_out.etval;
        eu_out.rob_wentry1.cwdata = eu_in.csr_alu_out.cdata;
      end

      if (eu_in.mem_issue0_valid) begin
        eu_out.rob_wtag0              = eu_in.mem_issue0.rob_tag;
        eu_out.rob_wen0               = 1;
        eu_out.rob_wentry0.done       = eu_in.mem_issue0.op.store;
        eu_out.rob_wentry0.store_addr = magu_out.address;
        eu_out.rob_wentry0.store_data = mstore_data;
        eu_out.rob_wentry0.store_strb = magu_out.byteenable;
        eu_out.rob_wentry0.exception  = magu_out.exception;
        eu_out.rob_wentry0.ecause     = magu_out.ecause;
        eu_out.rob_wentry0.etval      = magu_out.etval;
      end
    end
  end

endmodule
