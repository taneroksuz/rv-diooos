import constants::*;
import wires::*;
import functions::*;

module decode (
  input  logic           reset,
  input  logic           clock,
  input  logic           flush,
  input  logic           stall,
  input  decode_in_type  decode_in,
  output decode_out_type decode_out
);
  timeunit 1ns; timeprecision 1ps;

  decode_reg_type r, rin;
  decode_reg_type v;

  always_comb begin

    v                   = r;

    v.instr0.pc         = decode_in.ready0 ? decode_in.pc0 : 32'hFFFFFFFF;
    v.instr1.pc         = decode_in.ready1 ? decode_in.pc1 : 32'hFFFFFFFF;
    v.instr0.instr      = decode_in.ready0 ? decode_in.instr0 : 0;
    v.instr1.instr      = decode_in.ready1 ? decode_in.instr1 : 0;

    v.instr0.pred.taken = decode_in.btac_out.pred0.taken;
    v.instr1.pred.taken = decode_in.btac_out.pred1.taken;
    v.instr0.pred.taddr = decode_in.btac_out.pred0.taddr;
    v.instr1.pred.taddr = decode_in.btac_out.pred1.taddr;
    v.instr0.pred.tsat  = decode_in.btac_out.pred0.tsat;
    v.instr1.pred.tsat  = decode_in.btac_out.pred1.tsat;

    if (stall == 1) begin
      v.instr0 = r.instr0;
      v.instr1 = r.instr1;
    end

    if (v.instr0.pred.taken == 1) begin
      v.instr1 = init_instruction;
    end

    v.instr0.npc                  = v.instr0.pc + ((&v.instr0.instr[1:0]) ? 4 : 2);
    v.instr1.npc                  = v.instr1.pc + ((&v.instr1.instr[1:0]) ? 4 : 2);

    v.instr0.waddr                = v.instr0.instr[11:7];
    v.instr0.raddr1               = v.instr0.instr[19:15];
    v.instr0.raddr2               = v.instr0.instr[24:20];
    v.instr0.raddr3               = v.instr0.instr[31:27];
    v.instr0.caddr                = v.instr0.instr[31:20];

    v.instr1.waddr                = v.instr1.instr[11:7];
    v.instr1.raddr1               = v.instr1.instr[19:15];
    v.instr1.raddr2               = v.instr1.instr[24:20];
    v.instr1.raddr3               = v.instr1.instr[31:27];
    v.instr1.caddr                = v.instr1.instr[31:20];

    decode_out.base0_in.instr     = v.instr0.instr;

    v.instr0.instr_str            = decode_in.base0_out.instr_str;
    v.instr0.imm                  = decode_in.base0_out.imm;
    v.instr0.op.wren              = decode_in.base0_out.wren;
    v.instr0.op.rden1             = decode_in.base0_out.rden1;
    v.instr0.op.rden2             = decode_in.base0_out.rden2;
    v.instr0.op.cwren             = decode_in.base0_out.cwren;
    v.instr0.op.crden             = decode_in.base0_out.crden;
    v.instr0.op.alunit            = decode_in.base0_out.alunit;
    v.instr0.op.auipc             = decode_in.base0_out.auipc;
    v.instr0.op.lui               = decode_in.base0_out.lui;
    v.instr0.op.jal               = decode_in.base0_out.jal;
    v.instr0.op.jalr              = decode_in.base0_out.jalr;
    v.instr0.op.branch            = decode_in.base0_out.branch;
    v.instr0.op.load              = decode_in.base0_out.load;
    v.instr0.op.store             = decode_in.base0_out.store;
    v.instr0.op.nop               = decode_in.base0_out.nop;
    v.instr0.op.csreg             = decode_in.base0_out.csreg;
    v.instr0.op.division          = decode_in.base0_out.division;
    v.instr0.op.mult              = decode_in.base0_out.mult;
    v.instr0.op.bitm              = decode_in.base0_out.bitm;
    v.instr0.op.bitc              = decode_in.base0_out.bitc;
    v.instr0.op.fence             = decode_in.base0_out.fence;
    v.instr0.op.ecall             = decode_in.base0_out.ecall;
    v.instr0.op.ebreak            = decode_in.base0_out.ebreak;
    v.instr0.op.mret              = decode_in.base0_out.mret;
    v.instr0.op.wfi               = decode_in.base0_out.wfi;
    v.instr0.op.valid             = decode_in.base0_out.valid;
    v.instr0.alu_op               = decode_in.base0_out.alu_op;
    v.instr0.bcu_op               = decode_in.base0_out.bcu_op;
    v.instr0.lsu_op               = decode_in.base0_out.lsu_op;
    v.instr0.csr_op               = decode_in.base0_out.csr_op;
    v.instr0.div_op               = decode_in.base0_out.div_op;
    v.instr0.mul_op               = decode_in.base0_out.mul_op;
    v.instr0.bit_op               = decode_in.base0_out.bit_op;

    decode_out.base1_in.instr     = v.instr1.instr;

    v.instr1.instr_str            = decode_in.base1_out.instr_str;
    v.instr1.imm                  = decode_in.base1_out.imm;
    v.instr1.op.wren              = decode_in.base1_out.wren;
    v.instr1.op.rden1             = decode_in.base1_out.rden1;
    v.instr1.op.rden2             = decode_in.base1_out.rden2;
    v.instr1.op.cwren             = decode_in.base1_out.cwren;
    v.instr1.op.crden             = decode_in.base1_out.crden;
    v.instr1.op.alunit            = decode_in.base1_out.alunit;
    v.instr1.op.auipc             = decode_in.base1_out.auipc;
    v.instr1.op.lui               = decode_in.base1_out.lui;
    v.instr1.op.jal               = decode_in.base1_out.jal;
    v.instr1.op.jalr              = decode_in.base1_out.jalr;
    v.instr1.op.branch            = decode_in.base1_out.branch;
    v.instr1.op.load              = decode_in.base1_out.load;
    v.instr1.op.store             = decode_in.base1_out.store;
    v.instr1.op.nop               = decode_in.base1_out.nop;
    v.instr1.op.csreg             = decode_in.base1_out.csreg;
    v.instr1.op.division          = decode_in.base1_out.division;
    v.instr1.op.mult              = decode_in.base1_out.mult;
    v.instr1.op.bitm              = decode_in.base1_out.bitm;
    v.instr1.op.bitc              = decode_in.base1_out.bitc;
    v.instr1.op.fence             = decode_in.base1_out.fence;
    v.instr1.op.ecall             = decode_in.base1_out.ecall;
    v.instr1.op.ebreak            = decode_in.base1_out.ebreak;
    v.instr1.op.mret              = decode_in.base1_out.mret;
    v.instr1.op.wfi               = decode_in.base1_out.wfi;
    v.instr1.op.valid             = decode_in.base1_out.valid;
    v.instr1.alu_op               = decode_in.base1_out.alu_op;
    v.instr1.bcu_op               = decode_in.base1_out.bcu_op;
    v.instr1.lsu_op               = decode_in.base1_out.lsu_op;
    v.instr1.csr_op               = decode_in.base1_out.csr_op;
    v.instr1.div_op               = decode_in.base1_out.div_op;
    v.instr1.mul_op               = decode_in.base1_out.mul_op;
    v.instr1.bit_op               = decode_in.base1_out.bit_op;

    decode_out.compress0_in.instr = v.instr0.instr;

    if (decode_in.compress0_out.valid == 1) begin
      v.instr0.instr_str = decode_in.compress0_out.instr_str;
      v.instr0.imm       = decode_in.compress0_out.imm;
      v.instr0.waddr     = decode_in.compress0_out.waddr;
      v.instr0.raddr1    = decode_in.compress0_out.raddr1;
      v.instr0.raddr2    = decode_in.compress0_out.raddr2;
      v.instr0.op.wren   = decode_in.compress0_out.wren;
      v.instr0.op.rden1  = decode_in.compress0_out.rden1;
      v.instr0.op.rden2  = decode_in.compress0_out.rden2;
      v.instr0.op.alunit = decode_in.compress0_out.alunit;
      v.instr0.op.lui    = decode_in.compress0_out.lui;
      v.instr0.op.jal    = decode_in.compress0_out.jal;
      v.instr0.op.jalr   = decode_in.compress0_out.jalr;
      v.instr0.op.branch = decode_in.compress0_out.branch;
      v.instr0.op.load   = decode_in.compress0_out.load;
      v.instr0.op.store  = decode_in.compress0_out.store;
      v.instr0.op.nop    = decode_in.compress0_out.nop;
      v.instr0.op.ebreak = decode_in.compress0_out.ebreak;
      v.instr0.op.valid  = decode_in.compress0_out.valid;
      v.instr0.alu_op    = decode_in.compress0_out.alu_op;
      v.instr0.bcu_op    = decode_in.compress0_out.bcu_op;
      v.instr0.lsu_op    = decode_in.compress0_out.lsu_op;
    end

    decode_out.compress1_in.instr = v.instr1.instr;

    if (decode_in.compress1_out.valid == 1) begin
      v.instr1.instr_str = decode_in.compress1_out.instr_str;
      v.instr1.imm       = decode_in.compress1_out.imm;
      v.instr1.waddr     = decode_in.compress1_out.waddr;
      v.instr1.raddr1    = decode_in.compress1_out.raddr1;
      v.instr1.raddr2    = decode_in.compress1_out.raddr2;
      v.instr1.op.wren   = decode_in.compress1_out.wren;
      v.instr1.op.rden1  = decode_in.compress1_out.rden1;
      v.instr1.op.rden2  = decode_in.compress1_out.rden2;
      v.instr1.op.alunit = decode_in.compress1_out.alunit;
      v.instr1.op.lui    = decode_in.compress1_out.lui;
      v.instr1.op.jal    = decode_in.compress1_out.jal;
      v.instr1.op.jalr   = decode_in.compress1_out.jalr;
      v.instr1.op.branch = decode_in.compress1_out.branch;
      v.instr1.op.load   = decode_in.compress1_out.load;
      v.instr1.op.store  = decode_in.compress1_out.store;
      v.instr1.op.nop    = decode_in.compress1_out.nop;
      v.instr1.op.ebreak = decode_in.compress1_out.ebreak;
      v.instr1.op.valid  = decode_in.compress1_out.valid;
      v.instr1.alu_op    = decode_in.compress1_out.alu_op;
      v.instr1.bcu_op    = decode_in.compress1_out.bcu_op;
      v.instr1.lsu_op    = decode_in.compress1_out.lsu_op;
    end

    if (decode_in.ready0 == 1) begin
      if (v.instr0.op.valid == 0) begin
        v.instr0.op.exception = 1;
        v.instr0.op.valid     = 1;
      end
    end

    if (decode_in.ready1 == 1) begin
      if (v.instr1.op.valid == 0) begin
        v.instr1.op.exception = 1;
        v.instr1.op.valid     = 1;
      end
    end

    if (flush == 1) begin
      v.instr0 = init_instruction;
      v.instr1 = init_instruction;
    end

    rin               = v;

    decode_out.instr0 = r.instr0;
    decode_out.instr1 = r.instr1;

  end

  always_ff @(posedge clock) begin
    if (reset == 0) begin
      r <= init_decode_reg;
    end else begin
      r <= rin;
    end
  end

endmodule
