import constants::*;
import wires::*;
import functions::*;

module idecode (
    input  logic            reset,
    input  logic            clock,
    input  logic            flush,
    input  logic            stall,
    input  idecode_in_type  idecode_in,
    output idecode_out_type idecode_out
);
  timeunit 1ns; timeprecision 1ps;

  idecode_reg_type r, rin;
  idecode_reg_type v;

  always_comb begin

    v              = r;

    v.instr0.pc    = idecode_in.ready0 ? idecode_in.pc0 : 32'hFFFFFFFF;
    v.instr1.pc    = idecode_in.ready1 ? idecode_in.pc1 : 32'hFFFFFFFF;
    v.instr0.instr = idecode_in.ready0 ? idecode_in.instr0 : 0;
    v.instr1.instr = idecode_in.ready1 ? idecode_in.instr1 : 0;

    if (stall == 1) begin
      v.instr0 = r.instr0;
      v.instr1 = r.instr1;
    end

    v.instr0.npc                   = v.instr0.pc + ((&v.instr0.instr[1:0]) ? 4 : 2);
    v.instr1.npc                   = v.instr1.pc + ((&v.instr1.instr[1:0]) ? 4 : 2);

    v.instr0.waddr                 = v.instr0.instr[11:7];
    v.instr0.raddr1                = v.instr0.instr[19:15];
    v.instr0.raddr2                = v.instr0.instr[24:20];
    v.instr0.raddr3                = v.instr0.instr[31:27];
    v.instr0.caddr                 = v.instr0.instr[31:20];

    v.instr1.waddr                 = v.instr1.instr[11:7];
    v.instr1.raddr1                = v.instr1.instr[19:15];
    v.instr1.raddr2                = v.instr1.instr[24:20];
    v.instr1.raddr3                = v.instr1.instr[31:27];
    v.instr1.caddr                 = v.instr1.instr[31:20];

    idecode_out.decoder0_in.instr  = v.instr0.instr;

    v.instr0.instr_str             = idecode_in.decoder0_out.instr_str;
    v.instr0.imm                   = idecode_in.decoder0_out.imm;
    v.instr0.op.wren               = idecode_in.decoder0_out.wren;
    v.instr0.op.rden1              = idecode_in.decoder0_out.rden1;
    v.instr0.op.rden2              = idecode_in.decoder0_out.rden2;
    v.instr0.op.cwren              = idecode_in.decoder0_out.cwren;
    v.instr0.op.crden              = idecode_in.decoder0_out.crden;
    v.instr0.op.alunit             = idecode_in.decoder0_out.alunit;
    v.instr0.op.auipc              = idecode_in.decoder0_out.auipc;
    v.instr0.op.lui                = idecode_in.decoder0_out.lui;
    v.instr0.op.jal                = idecode_in.decoder0_out.jal;
    v.instr0.op.jalr               = idecode_in.decoder0_out.jalr;
    v.instr0.op.branch             = idecode_in.decoder0_out.branch;
    v.instr0.op.load               = idecode_in.decoder0_out.load;
    v.instr0.op.store              = idecode_in.decoder0_out.store;
    v.instr0.op.nop                = idecode_in.decoder0_out.nop;
    v.instr0.op.csreg              = idecode_in.decoder0_out.csreg;
    v.instr0.op.division           = idecode_in.decoder0_out.division;
    v.instr0.op.mult               = idecode_in.decoder0_out.mult;
    v.instr0.op.bitm               = idecode_in.decoder0_out.bitm;
    v.instr0.op.bitc               = idecode_in.decoder0_out.bitc;
    v.instr0.op.fence              = idecode_in.decoder0_out.fence;
    v.instr0.op.ecall              = idecode_in.decoder0_out.ecall;
    v.instr0.op.ebreak             = idecode_in.decoder0_out.ebreak;
    v.instr0.op.mret               = idecode_in.decoder0_out.mret;
    v.instr0.op.wfi                = idecode_in.decoder0_out.wfi;
    v.instr0.op.valid              = idecode_in.decoder0_out.valid;
    v.instr0.alu_op                = idecode_in.decoder0_out.alu_op;
    v.instr0.bcu_op                = idecode_in.decoder0_out.bcu_op;
    v.instr0.lsu_op                = idecode_in.decoder0_out.lsu_op;
    v.instr0.csr_op                = idecode_in.decoder0_out.csr_op;
    v.instr0.div_op                = idecode_in.decoder0_out.div_op;
    v.instr0.mul_op                = idecode_in.decoder0_out.mul_op;
    v.instr0.bit_op                = idecode_in.decoder0_out.bit_op;

    idecode_out.decoder1_in.instr  = v.instr1.instr;

    v.instr1.instr_str             = idecode_in.decoder1_out.instr_str;
    v.instr1.imm                   = idecode_in.decoder1_out.imm;
    v.instr1.op.wren               = idecode_in.decoder1_out.wren;
    v.instr1.op.rden1              = idecode_in.decoder1_out.rden1;
    v.instr1.op.rden2              = idecode_in.decoder1_out.rden2;
    v.instr1.op.cwren              = idecode_in.decoder1_out.cwren;
    v.instr1.op.crden              = idecode_in.decoder1_out.crden;
    v.instr1.op.alunit             = idecode_in.decoder1_out.alunit;
    v.instr1.op.auipc              = idecode_in.decoder1_out.auipc;
    v.instr1.op.lui                = idecode_in.decoder1_out.lui;
    v.instr1.op.jal                = idecode_in.decoder1_out.jal;
    v.instr1.op.jalr               = idecode_in.decoder1_out.jalr;
    v.instr1.op.branch             = idecode_in.decoder1_out.branch;
    v.instr1.op.load               = idecode_in.decoder1_out.load;
    v.instr1.op.store              = idecode_in.decoder1_out.store;
    v.instr1.op.nop                = idecode_in.decoder1_out.nop;
    v.instr1.op.csreg              = idecode_in.decoder1_out.csreg;
    v.instr1.op.division           = idecode_in.decoder1_out.division;
    v.instr1.op.mult               = idecode_in.decoder1_out.mult;
    v.instr1.op.bitm               = idecode_in.decoder1_out.bitm;
    v.instr1.op.bitc               = idecode_in.decoder1_out.bitc;
    v.instr1.op.fence              = idecode_in.decoder1_out.fence;
    v.instr1.op.ecall              = idecode_in.decoder1_out.ecall;
    v.instr1.op.ebreak             = idecode_in.decoder1_out.ebreak;
    v.instr1.op.mret               = idecode_in.decoder1_out.mret;
    v.instr1.op.wfi                = idecode_in.decoder1_out.wfi;
    v.instr1.op.valid              = idecode_in.decoder1_out.valid;
    v.instr1.alu_op                = idecode_in.decoder1_out.alu_op;
    v.instr1.bcu_op                = idecode_in.decoder1_out.bcu_op;
    v.instr1.lsu_op                = idecode_in.decoder1_out.lsu_op;
    v.instr1.csr_op                = idecode_in.decoder1_out.csr_op;
    v.instr1.div_op                = idecode_in.decoder1_out.div_op;
    v.instr1.mul_op                = idecode_in.decoder1_out.mul_op;
    v.instr1.bit_op                = idecode_in.decoder1_out.bit_op;

    idecode_out.compress0_in.instr = v.instr0.instr;

    if (idecode_in.compress0_out.valid == 1) begin
      v.instr0.instr_str = idecode_in.compress0_out.instr_str;
      v.instr0.imm       = idecode_in.compress0_out.imm;
      v.instr0.waddr     = idecode_in.compress0_out.waddr;
      v.instr0.raddr1    = idecode_in.compress0_out.raddr1;
      v.instr0.raddr2    = idecode_in.compress0_out.raddr2;
      v.instr0.op.wren   = idecode_in.compress0_out.wren;
      v.instr0.op.rden1  = idecode_in.compress0_out.rden1;
      v.instr0.op.rden2  = idecode_in.compress0_out.rden2;
      v.instr0.op.alunit = idecode_in.compress0_out.alunit;
      v.instr0.op.lui    = idecode_in.compress0_out.lui;
      v.instr0.op.jal    = idecode_in.compress0_out.jal;
      v.instr0.op.jalr   = idecode_in.compress0_out.jalr;
      v.instr0.op.branch = idecode_in.compress0_out.branch;
      v.instr0.op.load   = idecode_in.compress0_out.load;
      v.instr0.op.store  = idecode_in.compress0_out.store;
      v.instr0.op.nop    = idecode_in.compress0_out.nop;
      v.instr0.op.ebreak = idecode_in.compress0_out.ebreak;
      v.instr0.op.valid  = idecode_in.compress0_out.valid;
      v.instr0.alu_op    = idecode_in.compress0_out.alu_op;
      v.instr0.bcu_op    = idecode_in.compress0_out.bcu_op;
      v.instr0.lsu_op    = idecode_in.compress0_out.lsu_op;
    end

    idecode_out.compress1_in.instr = v.instr1.instr;

    if (idecode_in.compress1_out.valid == 1) begin
      v.instr1.instr_str = idecode_in.compress1_out.instr_str;
      v.instr1.imm       = idecode_in.compress1_out.imm;
      v.instr1.waddr     = idecode_in.compress1_out.waddr;
      v.instr1.raddr1    = idecode_in.compress1_out.raddr1;
      v.instr1.raddr2    = idecode_in.compress1_out.raddr2;
      v.instr1.op.wren   = idecode_in.compress1_out.wren;
      v.instr1.op.rden1  = idecode_in.compress1_out.rden1;
      v.instr1.op.rden2  = idecode_in.compress1_out.rden2;
      v.instr1.op.alunit = idecode_in.compress1_out.alunit;
      v.instr1.op.lui    = idecode_in.compress1_out.lui;
      v.instr1.op.jal    = idecode_in.compress1_out.jal;
      v.instr1.op.jalr   = idecode_in.compress1_out.jalr;
      v.instr1.op.branch = idecode_in.compress1_out.branch;
      v.instr1.op.load   = idecode_in.compress1_out.load;
      v.instr1.op.store  = idecode_in.compress1_out.store;
      v.instr1.op.nop    = idecode_in.compress1_out.nop;
      v.instr1.op.ebreak = idecode_in.compress1_out.ebreak;
      v.instr1.op.valid  = idecode_in.compress1_out.valid;
      v.instr1.alu_op    = idecode_in.compress1_out.alu_op;
      v.instr1.bcu_op    = idecode_in.compress1_out.bcu_op;
      v.instr1.lsu_op    = idecode_in.compress1_out.lsu_op;
    end

    if (idecode_in.ready0 == 1) begin
      if (v.instr0.op.valid == 0) begin
        v.instr0.op.exception = 1;
        v.instr0.op.valid     = 1;
      end
    end

    if (idecode_in.ready1 == 1) begin
      if (v.instr1.op.valid == 0) begin
        v.instr1.op.exception = 1;
        v.instr1.op.valid     = 1;
      end
    end

    if (flush == 1) begin
      v.instr0 = init_instruction;
      v.instr1 = init_instruction;
    end

    rin                = v;

    idecode_out.instr0 = r.instr0;
    idecode_out.instr1 = r.instr1;

  end

  always_ff @(posedge clock) begin
    if (reset == 0) begin
      r <= init_idecode_reg;
    end else begin
      r <= rin;
    end
  end

endmodule
