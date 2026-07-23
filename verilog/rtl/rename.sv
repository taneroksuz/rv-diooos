import configure::*;
import constants::*;
import wires::*;
import functions::*;
module rename (
  input  logic           reset,
  input  logic           clock,
  input  logic           flush,
  input  rename_in_type  rename_in,
  output rename_out_type rename_out
);
  timeunit 1ns; timeprecision 1ps;

  typedef struct packed {
    logic                     i0_is_mem;
    logic                     i1_is_mem;
    logic                     need_fl0;
    logic                     need_fl1;
    logic                     rs0_ok;
    logic                     rs1_ok;
    logic                     can_dispatch0;
    logic                     can_dispatch1;
    logic                     stall;
    logic [PRF_ADDR_BITS-1:0] pdest0;
    logic [PRF_ADDR_BITS-1:0] pdest1;
    rs_entry_type             e0;
    rs_entry_type             e1;
    rs_entry_type             em0;
    rs_entry_type             em1;
    rename_out_type           rename_out;
  } rename_reg_type;

  rename_reg_type v;
  cdb_type        cdb_load_any;

  always_comb begin
    v            = '0;
    v.rename_out = '0;
    cdb_load_any = rename_in.cdb_load0.valid ? rename_in.cdb_load0 : rename_in.cdb_load1;

    v.i0_is_mem = rename_in.instr0.op.load | rename_in.instr0.op.store;
    v.i1_is_mem = rename_in.instr1.op.load | rename_in.instr1.op.store;
    v.need_fl0 = rename_in.instr0_valid && rename_in.instr0.op.wren &&
        (rename_in.instr0.waddr != 5'h0);
    v.need_fl1 = rename_in.instr1_valid && rename_in.instr1.op.wren &&
        (rename_in.instr1.waddr != 5'h0);
    v.rs0_ok = rename_in.instr0_valid ?
        (v.i0_is_mem ? !rename_in.rs_mem_full : !rename_in.rs_int_full) : 1'b1;
    if (rename_in.instr1_valid) begin
      if (v.i1_is_mem) begin
        v.rs1_ok = (rename_in.instr0_valid && v.i0_is_mem) ? rename_in.rs_mem_has_two :
            !rename_in.rs_mem_full;
      end else begin
        v.rs1_ok = (rename_in.instr0_valid && !v.i0_is_mem) ? rename_in.rs_int_has_two :
            !rename_in.rs_int_full;
      end
    end else begin
      v.rs1_ok = 1'b1;
    end
    v.can_dispatch0 = rename_in.instr0_valid && !rename_in.rob_full &&
        (!v.need_fl0 || rename_in.fl.alloc_ok0) && v.rs0_ok && !flush;
    v.can_dispatch1 = rename_in.instr1_valid && v.can_dispatch0 && rename_in.rob_has_two &&
        (!v.need_fl1 || (v.need_fl0 ? rename_in.fl.alloc_ok1 : rename_in.fl.alloc_ok0)) &&
        v.rs1_ok && !flush;
    v.stall = (rename_in.instr0_valid && !v.can_dispatch0) ||
        (rename_in.instr1_valid && !v.can_dispatch1);
    if (v.stall) begin
      v.can_dispatch0 = 1'b0;
      v.can_dispatch1 = 1'b0;
    end
    v.pdest0 = v.need_fl0 ? rename_in.fl.alloc_tag0 : PRF_ADDR_BITS'(0);
    v.pdest1 = v.need_fl1 ? (v.need_fl0 ? rename_in.fl.alloc_tag1 : rename_in.fl.alloc_tag0) :
        PRF_ADDR_BITS'(0);

    v.rename_out.stall = v.stall;
    v.rename_out.fl.alloc0 = v.can_dispatch0 && v.need_fl0;
    v.rename_out.fl.alloc1 = v.can_dispatch1 && v.need_fl1;
    v.rename_out.rat.rsrc0_a = rename_in.instr0.op.rden1 ? rename_in.instr0.raddr1 : 5'h0;
    v.rename_out.rat.rsrc1_a = rename_in.instr0.op.rden2 ? rename_in.instr0.raddr2 : 5'h0;
    v.rename_out.rat.rsrc2_a = rename_in.instr1.op.rden1 ? rename_in.instr1.raddr1 : 5'h0;
    v.rename_out.rat.rsrc3_a = rename_in.instr1.op.rden2 ? rename_in.instr1.raddr2 : 5'h0;
    v.rename_out.rat.waddr0_a = rename_in.instr0.waddr;
    v.rename_out.rat.waddr0_p = v.pdest0;
    v.rename_out.rat.wren0 = v.can_dispatch0 && rename_in.instr0.op.wren &&
        (rename_in.instr0.waddr != 5'h0);
    v.rename_out.rat.waddr1_a = rename_in.instr1.waddr;
    v.rename_out.rat.waddr1_p = v.pdest1;
    v.rename_out.rat.wren1 = v.can_dispatch1 && rename_in.instr1.op.wren &&
        (rename_in.instr1.waddr != 5'h0);
    v.rename_out.rob_alloc0 = v.can_dispatch0;
    v.rename_out.rob_alloc1 = v.can_dispatch1;

    v.e0 = init_rs_entry;
    v.e0.valid = v.can_dispatch0 && !v.i0_is_mem;
    v.e0.psrc1 = rename_in.rat.psrc0;
    v.e0.psrc2 = rename_in.rat.psrc1;
    v.e0.src1_ready = !rename_in.instr0.op.rden1 || src_ready(
      rename_in.rat.psrc0,
      rename_in.rat.psrc0_valid && rename_in.prf.rvalid0,
      rename_in.cdb0,
      rename_in.cdb1,
      cdb_load_any
    );
    v.e0.src2_ready = !rename_in.instr0.op.rden2 || src_ready(
      rename_in.rat.psrc1,
      rename_in.rat.psrc1_valid && rename_in.prf.rvalid1,
      rename_in.cdb0,
      rename_in.cdb1,
      cdb_load_any
    );
    v.e0.rdata1 = rename_in.instr0.op.rden1 ? prf_or_cdb(
      rename_in.rat.psrc0,
      rename_in.rat.psrc0_valid && rename_in.prf.rvalid0,
      rename_in.prf.rdata0,
      rename_in.cdb0,
      rename_in.cdb1,
      cdb_load_any
    ) : 32'h0;
    v.e0.rdata2 = rename_in.instr0.op.rden2 ? prf_or_cdb(
      rename_in.rat.psrc1,
      rename_in.rat.psrc1_valid && rename_in.prf.rvalid1,
      rename_in.prf.rdata1,
      rename_in.cdb0,
      rename_in.cdb1,
      cdb_load_any
    ) : 32'h0;
    v.e0.pdest = v.pdest0;
    v.e0.rob_tag = rename_in.rob_tag0;
    v.e0.imm = rename_in.instr0.imm;
    v.e0.pc = rename_in.instr0.pc;
    v.e0.npc = rename_in.instr0.npc;
    v.e0.caddr = rename_in.instr0.caddr;
    v.e0.op = rename_in.instr0.op;
    v.e0.alu_op = rename_in.instr0.alu_op;
    v.e0.bcu_op = rename_in.instr0.bcu_op;
    v.e0.lsu_op = rename_in.instr0.lsu_op;
    v.e0.csr_op = rename_in.instr0.csr_op;
    v.e0.div_op = rename_in.instr0.div_op;
    v.e0.mul_op = rename_in.instr0.mul_op;
    v.e0.bit_op = rename_in.instr0.bit_op;

    v.e1 = init_rs_entry;
    v.e1.valid = v.can_dispatch1 && !v.i1_is_mem;
    v.e1.psrc1 = rename_in.rat.psrc2;
    v.e1.psrc2 = rename_in.rat.psrc3;
    v.e1.src1_ready = !rename_in.instr1.op.rden1 || src_ready(
      rename_in.rat.psrc2,
      rename_in.rat.psrc2_valid && rename_in.prf.rvalid2,
      rename_in.cdb0,
      rename_in.cdb1,
      cdb_load_any
    );
    v.e1.src2_ready = !rename_in.instr1.op.rden2 || src_ready(
      rename_in.rat.psrc3,
      rename_in.rat.psrc3_valid && rename_in.prf.rvalid3,
      rename_in.cdb0,
      rename_in.cdb1,
      cdb_load_any
    );
    v.e1.rdata1 = rename_in.instr1.op.rden1 ? prf_or_cdb(
      rename_in.rat.psrc2,
      rename_in.rat.psrc2_valid && rename_in.prf.rvalid2,
      rename_in.prf.rdata2,
      rename_in.cdb0,
      rename_in.cdb1,
      cdb_load_any
    ) : 32'h0;
    v.e1.rdata2 = rename_in.instr1.op.rden2 ? prf_or_cdb(
      rename_in.rat.psrc3,
      rename_in.rat.psrc3_valid && rename_in.prf.rvalid3,
      rename_in.prf.rdata3,
      rename_in.cdb0,
      rename_in.cdb1,
      cdb_load_any
    ) : 32'h0;
    v.e1.pdest = v.pdest1;
    v.e1.rob_tag = rename_in.rob_tag1;
    v.e1.imm = rename_in.instr1.imm;
    v.e1.pc = rename_in.instr1.pc;
    v.e1.npc = rename_in.instr1.npc;
    v.e1.caddr = rename_in.instr1.caddr;
    v.e1.op = rename_in.instr1.op;
    v.e1.alu_op = rename_in.instr1.alu_op;
    v.e1.bcu_op = rename_in.instr1.bcu_op;
    v.e1.lsu_op = rename_in.instr1.lsu_op;
    v.e1.csr_op = rename_in.instr1.csr_op;
    v.e1.div_op = rename_in.instr1.div_op;
    v.e1.mul_op = rename_in.instr1.mul_op;
    v.e1.bit_op = rename_in.instr1.bit_op;

    v.em0       = v.e0;
    v.em0.valid = v.can_dispatch0 && v.i0_is_mem;
    v.em1       = v.e1;
    v.em1.valid = v.can_dispatch1 && v.i1_is_mem;

    v.rename_out.rs_int_alloc0 = v.e0.valid;
    v.rename_out.rs_int_entry0 = v.e0;
    v.rename_out.rs_int_alloc1 = v.e1.valid;
    v.rename_out.rs_int_entry1 = v.e1;
    v.rename_out.rs_mem_alloc0 = v.em0.valid;
    v.rename_out.rs_mem_entry0 = v.em0;
    v.rename_out.rs_mem_alloc1 = v.em1.valid;
    v.rename_out.rs_mem_entry1 = v.em1;

    v.rename_out.rob_entry0 = init_rob_entry;
    v.rename_out.rob_entry0.valid = 1'b1;
    v.rename_out.rob_entry0.pc = rename_in.instr0.pc;
    v.rename_out.rob_entry0.npc = rename_in.instr0.npc;
    v.rename_out.rob_entry0.pnpc = rename_in.instr0.npc;
    v.rename_out.rob_entry0.pred = rename_in.instr0.pred;
    v.rename_out.rob_entry0.pdest = v.pdest0;
    v.rename_out.rob_entry0.adest = rename_in.instr0.waddr;
    v.rename_out.rob_entry0.wren = rename_in.instr0.op.wren && (rename_in.instr0.waddr != 5'h0);
    v.rename_out.rob_entry0.old_pdest = rename_in.rat.old_pdest0;
    v.rename_out.rob_entry0.store = rename_in.instr0.op.store;
    v.rename_out.rob_entry0.load = rename_in.instr0.op.load;
    v.rename_out.rob_entry0.lsu_op = rename_in.instr0.lsu_op;
    v.rename_out.rob_entry0.branch = rename_in.instr0.op.branch;
    v.rename_out.rob_entry0.jump = rename_in.instr0.op.jal | rename_in.instr0.op.jalr;
    v.rename_out.rob_entry0.mret = rename_in.instr0.op.mret;
    v.rename_out.rob_entry0.fence = rename_in.instr0.op.fence;
    v.rename_out.rob_entry0.ecall = rename_in.instr0.op.ecall;
    v.rename_out.rob_entry0.ebreak = rename_in.instr0.op.ebreak;
    v.rename_out.rob_entry0.wfi = rename_in.instr0.op.wfi;
    v.rename_out.rob_entry0.csreg = rename_in.instr0.op.csreg;
    v.rename_out.rob_entry0.cwren = rename_in.instr0.op.cwren;
    v.rename_out.rob_entry0.caddr = rename_in.instr0.caddr;

    v.rename_out.rob_entry1 = init_rob_entry;
    v.rename_out.rob_entry1.valid = 1'b1;
    v.rename_out.rob_entry1.pc = rename_in.instr1.pc;
    v.rename_out.rob_entry1.npc = rename_in.instr1.npc;
    v.rename_out.rob_entry1.pnpc = rename_in.instr1.npc;
    v.rename_out.rob_entry1.pred = rename_in.instr1.pred;
    v.rename_out.rob_entry1.pdest = v.pdest1;
    v.rename_out.rob_entry1.adest = rename_in.instr1.waddr;
    v.rename_out.rob_entry1.wren = rename_in.instr1.op.wren && (rename_in.instr1.waddr != 5'h0);
    v.rename_out.rob_entry1.old_pdest = rename_in.rat.old_pdest1;
    v.rename_out.rob_entry1.store = rename_in.instr1.op.store;
    v.rename_out.rob_entry1.load = rename_in.instr1.op.load;
    v.rename_out.rob_entry1.lsu_op = rename_in.instr1.lsu_op;
    v.rename_out.rob_entry1.branch = rename_in.instr1.op.branch;
    v.rename_out.rob_entry1.jump = rename_in.instr1.op.jal | rename_in.instr1.op.jalr;
    v.rename_out.rob_entry1.mret = rename_in.instr1.op.mret;
    v.rename_out.rob_entry1.fence = rename_in.instr1.op.fence;
    v.rename_out.rob_entry1.ecall = rename_in.instr1.op.ecall;
    v.rename_out.rob_entry1.ebreak = rename_in.instr1.op.ebreak;
    v.rename_out.rob_entry1.wfi = rename_in.instr1.op.wfi;
    v.rename_out.rob_entry1.csreg = rename_in.instr1.op.csreg;
    v.rename_out.rob_entry1.cwren = rename_in.instr1.op.cwren;
    v.rename_out.rob_entry1.caddr = rename_in.instr1.caddr;

    rename_out = v.rename_out;
  end
endmodule
