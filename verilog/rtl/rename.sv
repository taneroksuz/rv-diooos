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
    rs_entry_type  rs_int_entry0;
    logic [0:0]    rs_int_alloc0;
    rs_entry_type  rs_int_entry1;
    logic [0:0]    rs_int_alloc1;
    rs_entry_type  rs_mem_entry0;
    logic [0:0]    rs_mem_alloc0;
    rs_entry_type  rs_mem_entry1;
    logic [0:0]    rs_mem_alloc1;
    logic [0:0]    rob_alloc0;
    logic [0:0]    rob_alloc1;
    rob_entry_type rob_entry0;
    rob_entry_type rob_entry1;
    rat_in_type    rat;
    fl_in_type     fl;
    logic [0:0]    stall;
  } rename_reg_type;

  localparam rename_reg_type init_rename_reg = '{
      rs_int_entry0 : init_rs_entry,
      rs_int_alloc0 : 0,
      rs_int_entry1 : init_rs_entry,
      rs_int_alloc1 : 0,
      rs_mem_entry0 : init_rs_entry,
      rs_mem_alloc0 : 0,
      rs_mem_entry1 : init_rs_entry,
      rs_mem_alloc1 : 0,
      rob_alloc0    : 0,
      rob_alloc1    : 0,
      rob_entry0    : init_rob_entry,
      rob_entry1    : init_rob_entry,
      rat           : init_rat_in,
      fl            : init_fl_in,
      stall         : 0
  };

  rename_reg_type r, rin;
  rename_reg_type v;

  logic i0_is_mem, i1_is_mem;
  logic need_fl0, need_fl1;
  logic rs0_ok, rs1_ok;
  logic can_dispatch0, can_dispatch1;
  logic [PRF_ADDR_BITS-1:0] pdest0, pdest1;
  rs_entry_type e0, e1, em0, em1;

  assign i0_is_mem = rename_in.instr0.op.load | rename_in.instr0.op.store;
  assign i1_is_mem = rename_in.instr1.op.load | rename_in.instr1.op.store;

  assign need_fl0 = rename_in.instr0_valid && rename_in.instr0.op.wren;
  assign need_fl1 = rename_in.instr1_valid && rename_in.instr1.op.wren;

  assign rs0_ok = rename_in.instr0_valid ?
                  (i0_is_mem ? !rename_in.rs_mem_full : !rename_in.rs_int_full) : 1'b1;
  assign rs1_ok = rename_in.instr1_valid ?
                  (i1_is_mem ? rename_in.rs_mem_has_two : rename_in.rs_int_has_two) : 1'b1;

  assign can_dispatch0 = rename_in.instr0_valid && !rename_in.rob_full
                         && (!need_fl0 || rename_in.fl.alloc_ok0) && rs0_ok && !flush;
  assign can_dispatch1 = rename_in.instr1_valid && can_dispatch0 && rename_in.rob_has_two
                         && (!need_fl1 || (need_fl0 ? rename_in.fl.alloc_ok1 : rename_in.fl.alloc_ok0))
                         && rs1_ok && !flush;

  assign pdest0 = need_fl0 ? rename_in.fl.alloc_tag0 : PRF_ADDR_BITS'(0);
  assign pdest1 = need_fl1 ? (need_fl0 ? rename_in.fl.alloc_tag1
                                       : rename_in.fl.alloc_tag0)
                           : PRF_ADDR_BITS'(0);

  always_comb begin

    v = r;

    e0 = init_rs_entry;
    e0.valid = can_dispatch0 && !i0_is_mem;
    e0.psrc1 = rename_in.rat.psrc0;
    e0.psrc2 = rename_in.rat.psrc1;
    e0.src1_ready = !rename_in.instr0.op.rden1 || src_ready(
      rename_in.rat.psrc0,
      rename_in.rat.psrc0_valid,
      rename_in.cdb0,
      rename_in.cdb1,
      rename_in.cdb_load
    );
    e0.src2_ready = !rename_in.instr0.op.rden2 || src_ready(
      rename_in.rat.psrc1,
      rename_in.rat.psrc1_valid,
      rename_in.cdb0,
      rename_in.cdb1,
      rename_in.cdb_load
    );
    e0.rdata1 = prf_or_cdb(
      rename_in.rat.psrc0,
      rename_in.rat.psrc0_valid,
      rename_in.prf.rdata0,
      rename_in.cdb0,
      rename_in.cdb1,
      rename_in.cdb_load
    );
    e0.rdata2 = prf_or_cdb(
      rename_in.rat.psrc1,
      rename_in.rat.psrc1_valid,
      rename_in.prf.rdata1,
      rename_in.cdb0,
      rename_in.cdb1,
      rename_in.cdb_load
    );
    e0.pdest = pdest0;
    e0.rob_tag = rename_in.rob_tag0;
    e0.imm = rename_in.instr0.imm;
    e0.pc = rename_in.instr0.pc;
    e0.npc = rename_in.instr0.npc;
    e0.caddr = rename_in.instr0.caddr;
    e0.op = rename_in.instr0.op;
    e0.alu_op = rename_in.instr0.alu_op;
    e0.bcu_op = rename_in.instr0.bcu_op;
    e0.lsu_op = rename_in.instr0.lsu_op;
    e0.csr_op = rename_in.instr0.csr_op;
    e0.div_op = rename_in.instr0.div_op;
    e0.mul_op = rename_in.instr0.mul_op;
    e0.bit_op = rename_in.instr0.bit_op;

    e1 = init_rs_entry;
    e1.valid = can_dispatch1 && !i1_is_mem;
    e1.psrc1 = rename_in.rat.psrc2;
    e1.psrc2 = rename_in.rat.psrc3;
    e1.src1_ready = !rename_in.instr1.op.rden1 || src_ready(
      rename_in.rat.psrc2,
      rename_in.rat.psrc2_valid,
      rename_in.cdb0,
      rename_in.cdb1,
      rename_in.cdb_load
    );
    e1.src2_ready = !rename_in.instr1.op.rden2 || src_ready(
      rename_in.rat.psrc3,
      rename_in.rat.psrc3_valid,
      rename_in.cdb0,
      rename_in.cdb1,
      rename_in.cdb_load
    );
    e1.rdata1 = prf_or_cdb(
      rename_in.rat.psrc2,
      rename_in.rat.psrc2_valid,
      rename_in.prf.rdata2,
      rename_in.cdb0,
      rename_in.cdb1,
      rename_in.cdb_load
    );
    e1.rdata2 = prf_or_cdb(
      rename_in.rat.psrc3,
      rename_in.rat.psrc3_valid,
      rename_in.prf.rdata3,
      rename_in.cdb0,
      rename_in.cdb1,
      rename_in.cdb_load
    );
    e1.pdest = pdest1;
    e1.rob_tag = rename_in.rob_tag1;
    e1.imm = rename_in.instr1.imm;
    e1.pc = rename_in.instr1.pc;
    e1.npc = rename_in.instr1.npc;
    e1.caddr = rename_in.instr1.caddr;
    e1.op = rename_in.instr1.op;
    e1.alu_op = rename_in.instr1.alu_op;
    e1.bcu_op = rename_in.instr1.bcu_op;
    e1.lsu_op = rename_in.instr1.lsu_op;
    e1.csr_op = rename_in.instr1.csr_op;
    e1.div_op = rename_in.instr1.div_op;
    e1.mul_op = rename_in.instr1.mul_op;
    e1.bit_op = rename_in.instr1.bit_op;

    em0 = e0;
    em0.valid = can_dispatch0 && i0_is_mem;
    em1 = e1;
    em1.valid = can_dispatch1 && i1_is_mem;

    v.stall = rename_in.instr0_valid && !can_dispatch0;

    v.fl.alloc0 = need_fl0;
    v.fl.alloc1 = need_fl1;
    v.fl.free_tag0 = '0;
    v.fl.free_en0 = 1'b0;
    v.fl.free_tag1 = '0;
    v.fl.free_en1 = 1'b0;

    v.rat.rsrc0_a = rename_in.instr0.raddr1;
    v.rat.rsrc1_a = rename_in.instr0.raddr2;
    v.rat.rsrc2_a = rename_in.instr1.raddr1;
    v.rat.rsrc3_a = rename_in.instr1.raddr2;
    v.rat.waddr0_a = rename_in.instr0.waddr;
    v.rat.waddr0_p = pdest0;
    v.rat.wren0 = can_dispatch0 && rename_in.instr0.op.wren;
    v.rat.waddr1_a = rename_in.instr1.waddr;
    v.rat.waddr1_p = pdest1;
    v.rat.wren1 = can_dispatch1 && rename_in.instr1.op.wren;
    v.rat.commit_addr0 = '0;
    v.rat.commit_tag0 = '0;
    v.rat.commit_en0 = 1'b0;
    v.rat.commit_addr1 = '0;
    v.rat.commit_tag1 = '0;
    v.rat.commit_en1 = 1'b0;

    v.rob_alloc0 = can_dispatch0;
    v.rob_alloc1 = can_dispatch1;

    v.rob_entry0 = init_rob_entry;
    v.rob_entry0.valid = 1'b1;
    v.rob_entry0.pc = rename_in.instr0.pc;
    v.rob_entry0.npc = rename_in.instr0.npc;
    v.rob_entry0.pdest = pdest0;
    v.rob_entry0.adest = rename_in.instr0.waddr;
    v.rob_entry0.wren = rename_in.instr0.op.wren;
    v.rob_entry0.old_pdest = rename_in.rat.old_pdest0;
    v.rob_entry0.store = rename_in.instr0.op.store;
    v.rob_entry0.load = rename_in.instr0.op.load;
    v.rob_entry0.lsu_op = rename_in.instr0.lsu_op;
    v.rob_entry0.branch = rename_in.instr0.op.branch;
    v.rob_entry0.jump = rename_in.instr0.op.jal | rename_in.instr0.op.jalr;
    v.rob_entry0.mret = rename_in.instr0.op.mret;
    v.rob_entry0.fence = rename_in.instr0.op.fence;
    v.rob_entry0.ecall = rename_in.instr0.op.ecall;
    v.rob_entry0.ebreak = rename_in.instr0.op.ebreak;
    v.rob_entry0.wfi = rename_in.instr0.op.wfi;
    v.rob_entry0.csreg = rename_in.instr0.op.csreg;
    v.rob_entry0.cwren = rename_in.instr0.op.cwren;
    v.rob_entry0.caddr = rename_in.instr0.caddr;

    v.rob_entry1 = init_rob_entry;
    v.rob_entry1.valid = 1'b1;
    v.rob_entry1.pc = rename_in.instr1.pc;
    v.rob_entry1.npc = rename_in.instr1.npc;
    v.rob_entry1.pdest = pdest1;
    v.rob_entry1.adest = rename_in.instr1.waddr;
    v.rob_entry1.wren = rename_in.instr1.op.wren;
    v.rob_entry1.old_pdest = rename_in.rat.old_pdest1;
    v.rob_entry1.store = rename_in.instr1.op.store;
    v.rob_entry1.load = rename_in.instr1.op.load;
    v.rob_entry1.lsu_op = rename_in.instr1.lsu_op;
    v.rob_entry1.branch = rename_in.instr1.op.branch;
    v.rob_entry1.jump = rename_in.instr1.op.jal | rename_in.instr1.op.jalr;
    v.rob_entry1.mret = rename_in.instr1.op.mret;
    v.rob_entry1.fence = rename_in.instr1.op.fence;
    v.rob_entry1.ecall = rename_in.instr1.op.ecall;
    v.rob_entry1.ebreak = rename_in.instr1.op.ebreak;
    v.rob_entry1.wfi = rename_in.instr1.op.wfi;
    v.rob_entry1.csreg = rename_in.instr1.op.csreg;
    v.rob_entry1.cwren = rename_in.instr1.op.cwren;
    v.rob_entry1.caddr = rename_in.instr1.caddr;

    v.rs_int_entry0 = e0;
    v.rs_int_alloc0 = e0.valid;
    v.rs_int_entry1 = e1;
    v.rs_int_alloc1 = e1.valid;
    v.rs_mem_entry0 = em0;
    v.rs_mem_alloc0 = em0.valid;
    v.rs_mem_entry1 = em1;
    v.rs_mem_alloc1 = em1.valid;

    rin = v;

    rename_out.stall = r.stall;
    rename_out.fl = r.fl;
    rename_out.rat = r.rat;
    rename_out.rob_alloc0 = r.rob_alloc0;
    rename_out.rob_alloc1 = r.rob_alloc1;
    rename_out.rob_entry0 = r.rob_entry0;
    rename_out.rob_entry1 = r.rob_entry1;
    rename_out.rs_int_entry0 = r.rs_int_entry0;
    rename_out.rs_int_alloc0 = r.rs_int_alloc0;
    rename_out.rs_int_entry1 = r.rs_int_entry1;
    rename_out.rs_int_alloc1 = r.rs_int_alloc1;
    rename_out.rs_mem_entry0 = r.rs_mem_entry0;
    rename_out.rs_mem_alloc0 = r.rs_mem_alloc0;
    rename_out.rs_mem_entry1 = r.rs_mem_entry1;
    rename_out.rs_mem_alloc1 = r.rs_mem_alloc1;

  end

  always_ff @(posedge clock) begin
    if (reset == 0) begin
      r <= init_rename_reg;
    end else if (flush) begin
      r <= init_rename_reg;
    end else begin
      r <= rin;
    end
  end

endmodule
