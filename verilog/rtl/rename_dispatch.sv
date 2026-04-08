import configure::*;
import constants::*;
import wires::*;

module rename_dispatch (
    input  logic           reset,
    input  logic           clock,
    input  logic           flush,
    input  rename_in_type  rin,
    output rename_out_type rout
);
  timeunit 1ns; timeprecision 1ps;

  logic i0_is_mem, i1_is_mem;
  assign i0_is_mem = rin.instr0.op.load | rin.instr0.op.store;
  assign i1_is_mem = rin.instr1.op.load | rin.instr1.op.store;

  logic need_fl0, need_fl1;
  assign need_fl0 = rin.instr0_valid && rin.instr0.op.wren;
  assign need_fl1 = rin.instr1_valid && rin.instr1.op.wren;

  assign rout.fl.alloc0 = need_fl0;
  assign rout.fl.alloc1 = need_fl1;
  assign rout.fl.free_tag0 = '0;
  assign rout.fl.free_en0 = 0;
  assign rout.fl.free_tag1 = '0;
  assign rout.fl.free_en1 = 0;

  logic rs0_ok, rs1_ok;
  assign rs0_ok = rin.instr0_valid ? (i0_is_mem ? !rin.rs_mem_full : !rin.rs_int_full) : 1;
  assign rs1_ok = rin.instr1_valid ? (i1_is_mem ? rin.rs_mem_has_two : rin.rs_int_has_two) : 1;

  logic can_dispatch0, can_dispatch1;
  assign can_dispatch0 = rin.instr0_valid && !rin.rob_full
                         && (!need_fl0 || rin.fl.alloc_ok0) && rs0_ok && !flush;
  assign can_dispatch1 = rin.instr1_valid && can_dispatch0 && rin.rob_has_two
                         && (!need_fl1 || (need_fl0 ? rin.fl.alloc_ok1 : rin.fl.alloc_ok0))
                         && rs1_ok && !flush;

  assign rout.stall = rin.instr0_valid && !can_dispatch0;

  assign rout.rat.rsrc0_a = rin.instr0.raddr1;
  assign rout.rat.rsrc1_a = rin.instr0.raddr2;
  assign rout.rat.rsrc2_a = rin.instr1.raddr1;
  assign rout.rat.rsrc3_a = rin.instr1.raddr2;
  assign rout.rat.waddr0_a = rin.instr0.waddr;
  assign rout.rat.waddr1_a = rin.instr1.waddr;
  assign rout.rat.wren0 = can_dispatch0 && rin.instr0.op.wren;
  assign rout.rat.wren1 = can_dispatch1 && rin.instr1.op.wren;
  assign rout.rat.commit_addr0 = '0;
  assign rout.rat.commit_tag0 = '0;
  assign rout.rat.commit_en0 = 0;
  assign rout.rat.commit_addr1 = '0;
  assign rout.rat.commit_tag1 = '0;
  assign rout.rat.commit_en1 = 0;

  logic [PRF_ADDR_BITS-1:0] pdest0, pdest1;
  assign pdest0 = need_fl0 ? rin.fl.alloc_tag0 : PRF_ADDR_BITS'(0);
  assign pdest1 = need_fl1 ? (need_fl0 ? rin.fl.alloc_tag1 : rin.fl.alloc_tag0) : PRF_ADDR_BITS'(0);

  assign rout.rat.waddr0_p = pdest0;
  assign rout.rat.waddr1_p = pdest1;

  function automatic logic [31:0] prf_or_cdb(
      input logic [PRF_ADDR_BITS-1:0] tag, input logic prf_valid, input logic [31:0] prf_data,
      input cdb_type c0, input cdb_type c1, input cdb_type cl);
    if (c0.valid && c0.tag == tag) return c0.data;
    else if (c1.valid && c1.tag == tag) return c1.data;
    else if (cl.valid && cl.tag == tag) return cl.data;
    else if (prf_valid) return prf_data;
    else return 32'h0;
  endfunction

  function automatic logic src_ready(input logic [PRF_ADDR_BITS-1:0] tag, input logic prf_valid,
                                     input cdb_type c0, input cdb_type c1, input cdb_type cl);
    if (c0.valid && c0.tag == tag) return 1'b1;
    else if (c1.valid && c1.tag == tag) return 1'b1;
    else if (cl.valid && cl.tag == tag) return 1'b1;
    else return prf_valid;
  endfunction

  rs_entry_type e0, e1, em0, em1;

  always_comb begin
    e0 = init_rs_entry;
    e0.valid = can_dispatch0 && !i0_is_mem;
    e0.psrc1 = rin.rat.psrc0;
    e0.psrc2 = rin.rat.psrc1;
    e0.src1_ready = !rin.instr0.op.rden1 ||
        src_ready(rin.rat.psrc0, rin.rat.psrc0_valid, rin.cdb0, rin.cdb1, rin.cdb_load);
    e0.src2_ready = !rin.instr0.op.rden2 ||
        src_ready(rin.rat.psrc1, rin.rat.psrc1_valid, rin.cdb0, rin.cdb1, rin.cdb_load);
    e0.rdata1 = prf_or_cdb(rin.rat.psrc0, rin.rat.psrc0_valid, rin.prf.rdata0, rin.cdb0, rin.cdb1,
                           rin.cdb_load);
    e0.rdata2 = prf_or_cdb(rin.rat.psrc1, rin.rat.psrc1_valid, rin.prf.rdata1, rin.cdb0, rin.cdb1,
                           rin.cdb_load);
    e0.pdest = pdest0;
    e0.rob_tag = rin.rob_tag0;
    e0.imm = rin.instr0.imm;
    e0.pc = rin.instr0.pc;
    e0.npc = rin.instr0.npc;
    e0.caddr = rin.instr0.caddr;
    e0.op = rin.instr0.op;
    e0.alu_op = rin.instr0.alu_op;
    e0.bcu_op = rin.instr0.bcu_op;
    e0.lsu_op = rin.instr0.lsu_op;
    e0.csr_op = rin.instr0.csr_op;
    e0.div_op = rin.instr0.div_op;
    e0.mul_op = rin.instr0.mul_op;
    e0.bit_op = rin.instr0.bit_op;

    e1 = init_rs_entry;
    e1.valid = can_dispatch1 && !i1_is_mem;
    e1.psrc1 = rin.rat.psrc2;
    e1.psrc2 = rin.rat.psrc3;
    e1.src1_ready = !rin.instr1.op.rden1 ||
        src_ready(rin.rat.psrc2, rin.rat.psrc2_valid, rin.cdb0, rin.cdb1, rin.cdb_load);
    e1.src2_ready = !rin.instr1.op.rden2 ||
        src_ready(rin.rat.psrc3, rin.rat.psrc3_valid, rin.cdb0, rin.cdb1, rin.cdb_load);
    e1.rdata1 = prf_or_cdb(rin.rat.psrc2, rin.rat.psrc2_valid, rin.prf.rdata2, rin.cdb0, rin.cdb1,
                           rin.cdb_load);
    e1.rdata2 = prf_or_cdb(rin.rat.psrc3, rin.rat.psrc3_valid, rin.prf.rdata3, rin.cdb0, rin.cdb1,
                           rin.cdb_load);
    e1.pdest = pdest1;
    e1.rob_tag = rin.rob_tag1;
    e1.imm = rin.instr1.imm;
    e1.pc = rin.instr1.pc;
    e1.npc = rin.instr1.npc;
    e1.caddr = rin.instr1.caddr;
    e1.op = rin.instr1.op;
    e1.alu_op = rin.instr1.alu_op;
    e1.bcu_op = rin.instr1.bcu_op;
    e1.lsu_op = rin.instr1.lsu_op;
    e1.csr_op = rin.instr1.csr_op;
    e1.div_op = rin.instr1.div_op;
    e1.mul_op = rin.instr1.mul_op;
    e1.bit_op = rin.instr1.bit_op;

    em0 = e0;
    em0.valid = can_dispatch0 && i0_is_mem;
    em1 = e1;
    em1.valid = can_dispatch1 && i1_is_mem;
  end

  assign rout.rs_int_entry0 = e0;
  assign rout.rs_int_alloc0 = e0.valid;
  assign rout.rs_int_entry1 = e1;
  assign rout.rs_int_alloc1 = e1.valid;
  assign rout.rs_mem_entry0 = em0;
  assign rout.rs_mem_alloc0 = em0.valid;
  assign rout.rs_mem_entry1 = em1;
  assign rout.rs_mem_alloc1 = em1.valid;
  assign rout.rob_alloc0    = can_dispatch0;
  assign rout.rob_alloc1    = can_dispatch1;

  always_comb begin
    rout.rob_entry0 = init_rob_entry;
    rout.rob_entry0.valid  = 1;
    rout.rob_entry0.pc   = rin.instr0.pc;
    rout.rob_entry0.npc    = rin.instr0.npc;
    rout.rob_entry0.pdest = pdest0;
    rout.rob_entry0.adest  = rin.instr0.waddr;
    rout.rob_entry0.wren = rin.instr0.op.wren;
    rout.rob_entry0.old_pdest = rin.rat.old_pdest0;
    rout.rob_entry0.store  = rin.instr0.op.store;
    rout.rob_entry0.load = rin.instr0.op.load;
    rout.rob_entry0.lsu_op = rin.instr0.lsu_op;
    rout.rob_entry0.branch = rin.instr0.op.branch;
    rout.rob_entry0.jump   = rin.instr0.op.jal | rin.instr0.op.jalr;
    rout.rob_entry0.mret   = rin.instr0.op.mret;
    rout.rob_entry0.fence = rin.instr0.op.fence;
    rout.rob_entry0.ecall  = rin.instr0.op.ecall;
    rout.rob_entry0.ebreak = rin.instr0.op.ebreak;
    rout.rob_entry0.wfi    = rin.instr0.op.wfi;
    rout.rob_entry0.csreg = rin.instr0.op.csreg;
    rout.rob_entry0.cwren  = rin.instr0.op.cwren;
    rout.rob_entry0.caddr = rin.instr0.caddr;

    rout.rob_entry1 = init_rob_entry;
    rout.rob_entry1.valid  = 1;
    rout.rob_entry1.pc   = rin.instr1.pc;
    rout.rob_entry1.npc    = rin.instr1.npc;
    rout.rob_entry1.pdest = pdest1;
    rout.rob_entry1.adest  = rin.instr1.waddr;
    rout.rob_entry1.wren = rin.instr1.op.wren;
    rout.rob_entry1.old_pdest = rin.rat.old_pdest1;
    rout.rob_entry1.store  = rin.instr1.op.store;
    rout.rob_entry1.load = rin.instr1.op.load;
    rout.rob_entry1.lsu_op = rin.instr1.lsu_op;
    rout.rob_entry1.branch = rin.instr1.op.branch;
    rout.rob_entry1.jump   = rin.instr1.op.jal | rin.instr1.op.jalr;
    rout.rob_entry1.mret   = rin.instr1.op.mret;
    rout.rob_entry1.fence = rin.instr1.op.fence;
    rout.rob_entry1.ecall  = rin.instr1.op.ecall;
    rout.rob_entry1.ebreak = rin.instr1.op.ebreak;
    rout.rob_entry1.wfi    = rin.instr1.op.wfi;
    rout.rob_entry1.csreg = rin.instr1.op.csreg;
    rout.rob_entry1.cwren  = rin.instr1.op.cwren;
    rout.rob_entry1.caddr = rin.instr1.caddr;
  end

endmodule
