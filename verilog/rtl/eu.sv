import configure::*;
import constants::*;
import wires::*;
import functions::*;

module eu (
  input  logic       reset,
  input  logic       clock,
  input  logic       flush,
  input  eu_in_type  eu_in,
  output eu_out_type eu_out
);
  timeunit 1ns; timeprecision 1ps;

  typedef struct packed {
    cdb_type                  cdb0;
    cdb_type                  cdb1;
    logic [ROB_ADDR_BITS-1:0] rob_wtag0;
    rob_entry_type            rob_wentry0;
    logic [0:0]               rob_wen0;
    logic [ROB_ADDR_BITS-1:0] rob_wtag1;
    rob_entry_type            rob_wentry1;
    logic [0:0]               rob_wen1;
    logic [ROB_ADDR_BITS-1:0] rob_wtag_store;
    rob_entry_type            rob_wentry_store;
    logic [0:0]               rob_wen_store;
    rs_entry_type             div_pending;
    logic [0:0]               div_pending_valid;
    rs_entry_type             clmul_pending;
    logic [0:0]               clmul_pending_valid;
  } eu_reg_type;

  localparam eu_reg_type init_eu_reg = '{
      cdb0               : init_cdb,
      cdb1               : init_cdb,
      rob_wtag0          : '0,
      rob_wentry0        : init_rob_entry,
      rob_wen0           : 0,
      rob_wtag1          : '0,
      rob_wentry1        : init_rob_entry,
      rob_wen1           : 0,
      rob_wtag_store     : '0,
      rob_wentry_store   : init_rob_entry,
      rob_wen_store      : 0,
      div_pending        : init_rs_entry,
      div_pending_valid  : 0,
      clmul_pending      : init_rs_entry,
      clmul_pending_valid: 0
  };

  eu_reg_type r, rin;
  eu_reg_type v;

  logic branch0_taken, branch1_taken;
  logic [31:0] eu0_result, eu1_result;
  logic eu0_done, eu1_done;
  logic [31:0] mstore_data;

  logic div_issue0, div_issue1;
  logic clmul_issue0, clmul_issue1;

  always_comb begin

    v = r;

    v.cdb0 = init_cdb;
    v.cdb1 = init_cdb;
    v.rob_wtag0 = eu_in.int_issue0.rob_tag;
    v.rob_wentry0 = init_rob_entry;
    v.rob_wen0 = 1'b0;
    v.rob_wtag1 = eu_in.int_issue1.rob_tag;
    v.rob_wentry1 = init_rob_entry;
    v.rob_wen1 = 1'b0;
    v.rob_wtag_store = eu_in.mem_store_issue.rob_tag;
    v.rob_wentry_store = init_rob_entry;
    v.rob_wen_store = 1'b0;

    div_issue0 = eu_in.int_issue0_valid & eu_in.int_issue0.op.division & ~r.div_pending_valid;
    div_issue1   = eu_in.int_issue1_valid & eu_in.int_issue1.op.division & ~r.div_pending_valid & ~div_issue0;
    clmul_issue0 = eu_in.int_issue0_valid & eu_in.int_issue0.op.bitc & ~r.clmul_pending_valid;
    clmul_issue1 = eu_in.int_issue1_valid & eu_in.int_issue1.op.bitc    & ~r.clmul_pending_valid & ~clmul_issue0;

    if (flush) begin
      v.div_pending_valid   = 1'b0;
      v.clmul_pending_valid = 1'b0;
    end else begin
      if (eu_in.div_out.ready) begin
        v.div_pending_valid = 1'b0;
      end else if (div_issue0) begin
        v.div_pending       = eu_in.int_issue0;
        v.div_pending_valid = 1'b1;
      end else if (div_issue1) begin
        v.div_pending       = eu_in.int_issue1;
        v.div_pending_valid = 1'b1;
      end

      if (eu_in.bit_clmul_out.ready) begin
        v.clmul_pending_valid = 1'b0;
      end else if (clmul_issue0) begin
        v.clmul_pending       = eu_in.int_issue0;
        v.clmul_pending_valid = 1'b1;
      end else if (clmul_issue1) begin
        v.clmul_pending       = eu_in.int_issue1;
        v.clmul_pending_valid = 1'b1;
      end
    end

    eu_out.agu0_in.rdata1 = eu_in.int_issue0.rdata1;
    eu_out.agu0_in.imm = eu_in.int_issue0.imm;
    eu_out.agu0_in.pc = eu_in.int_issue0.pc;
    eu_out.agu0_in.auipc = eu_in.int_issue0.op.auipc;
    eu_out.agu0_in.jal = eu_in.int_issue0.op.jal;
    eu_out.agu0_in.jalr = eu_in.int_issue0.op.jalr;
    eu_out.agu0_in.branch = eu_in.int_issue0.op.branch;
    eu_out.agu0_in.load = 1'b0;
    eu_out.agu0_in.store = 1'b0;
    eu_out.agu0_in.lsu_op = init_lsu_op;

    eu_out.agu1_in.rdata1 = eu_in.int_issue1.rdata1;
    eu_out.agu1_in.imm = eu_in.int_issue1.imm;
    eu_out.agu1_in.pc = eu_in.int_issue1.pc;
    eu_out.agu1_in.auipc = eu_in.int_issue1.op.auipc;
    eu_out.agu1_in.jal = eu_in.int_issue1.op.jal;
    eu_out.agu1_in.jalr = eu_in.int_issue1.op.jalr;
    eu_out.agu1_in.branch = eu_in.int_issue1.op.branch;
    eu_out.agu1_in.load = 1'b0;
    eu_out.agu1_in.store = 1'b0;
    eu_out.agu1_in.lsu_op = init_lsu_op;

    eu_out.agu2_in.rdata1 = eu_in.mem_load_issue.rdata1;
    eu_out.agu2_in.imm = eu_in.mem_load_issue.imm;
    eu_out.agu2_in.pc = eu_in.mem_load_issue.pc;
    eu_out.agu2_in.auipc = 1'b0;
    eu_out.agu2_in.jal = 1'b0;
    eu_out.agu2_in.jalr = 1'b0;
    eu_out.agu2_in.branch = 1'b0;
    eu_out.agu2_in.load = eu_in.mem_load_issue.op.load;
    eu_out.agu2_in.store = 1'b0;
    eu_out.agu2_in.lsu_op = eu_in.mem_load_issue.lsu_op;

    eu_out.agu3_in.rdata1 = eu_in.mem_store_issue.rdata1;
    eu_out.agu3_in.imm = eu_in.mem_store_issue.imm;
    eu_out.agu3_in.pc = eu_in.mem_store_issue.pc;
    eu_out.agu3_in.auipc = 1'b0;
    eu_out.agu3_in.jal = 1'b0;
    eu_out.agu3_in.jalr = 1'b0;
    eu_out.agu3_in.branch = 1'b0;
    eu_out.agu3_in.load = 1'b0;
    eu_out.agu3_in.store = eu_in.mem_store_issue.op.store;
    eu_out.agu3_in.lsu_op = eu_in.mem_store_issue.lsu_op;

    eu_out.alu0_in.rdata1 = eu_in.int_issue0.rdata1;
    eu_out.alu0_in.rdata2 = eu_in.int_issue0.rdata2;
    eu_out.alu0_in.imm = eu_in.int_issue0.imm;
    eu_out.alu0_in.sel = eu_in.int_issue0.op.rden2;
    eu_out.alu0_in.alu_op = eu_in.int_issue0.alu_op;

    eu_out.alu1_in.rdata1 = eu_in.int_issue1.rdata1;
    eu_out.alu1_in.rdata2 = eu_in.int_issue1.rdata2;
    eu_out.alu1_in.imm = eu_in.int_issue1.imm;
    eu_out.alu1_in.sel = eu_in.int_issue1.op.rden2;
    eu_out.alu1_in.alu_op = eu_in.int_issue1.alu_op;

    eu_out.bcu0_in.rdata1 = eu_in.int_issue0.rdata1;
    eu_out.bcu0_in.rdata2 = eu_in.int_issue0.rdata2;
    eu_out.bcu0_in.enable = eu_in.int_issue0.op.branch;
    eu_out.bcu0_in.bcu_op = eu_in.int_issue0.bcu_op;

    eu_out.bcu1_in.rdata1 = eu_in.int_issue1.rdata1;
    eu_out.bcu1_in.rdata2 = eu_in.int_issue1.rdata2;
    eu_out.bcu1_in.enable = eu_in.int_issue1.op.branch;
    eu_out.bcu1_in.bcu_op = eu_in.int_issue1.bcu_op;

    branch0_taken = eu_in.int_issue0.op.branch & eu_in.bcu0_out.branch;
    branch1_taken = eu_in.int_issue1.op.branch & eu_in.bcu1_out.branch;

    eu_out.mul_in.rdata1 = eu_in.int_issue0.op.mult ? eu_in.int_issue0.rdata1
                                                     : eu_in.int_issue1.rdata1;
    eu_out.mul_in.rdata2 = eu_in.int_issue0.op.mult ? eu_in.int_issue0.rdata2
                                                     : eu_in.int_issue1.rdata2;
    eu_out.mul_in.mul_op = eu_in.int_issue0.op.mult ? eu_in.int_issue0.mul_op
                                                     : eu_in.int_issue1.mul_op;

    eu_out.div_in.rdata1 = div_issue0 ? eu_in.int_issue0.rdata1 : eu_in.int_issue1.rdata1;
    eu_out.div_in.rdata2 = div_issue0 ? eu_in.int_issue0.rdata2 : eu_in.int_issue1.rdata2;
    eu_out.div_in.div_op = div_issue0 ? eu_in.int_issue0.div_op : eu_in.int_issue1.div_op;
    eu_out.div_in.enable = div_issue0 | div_issue1;

    eu_out.bit_alu0_in.rdata1 = eu_in.int_issue0.rdata1;
    eu_out.bit_alu0_in.rdata2 = eu_in.int_issue0.rdata2;
    eu_out.bit_alu0_in.imm = eu_in.int_issue0.imm;
    eu_out.bit_alu0_in.sel = eu_in.int_issue0.op.rden2;
    eu_out.bit_alu0_in.bit_op = eu_in.int_issue0.bit_op;

    eu_out.bit_alu1_in.rdata1 = eu_in.int_issue1.rdata1;
    eu_out.bit_alu1_in.rdata2 = eu_in.int_issue1.rdata2;
    eu_out.bit_alu1_in.imm = eu_in.int_issue1.imm;
    eu_out.bit_alu1_in.sel = eu_in.int_issue1.op.rden2;
    eu_out.bit_alu1_in.bit_op = eu_in.int_issue1.bit_op;

    eu_out.bit_clmul_in.rdata1 = clmul_issue0 ? eu_in.int_issue0.rdata1 : eu_in.int_issue1.rdata1;
    eu_out.bit_clmul_in.rdata2 = clmul_issue0 ? eu_in.int_issue0.rdata2 : eu_in.int_issue1.rdata2;
    eu_out.bit_clmul_in.enable = clmul_issue0 | clmul_issue1;
    eu_out.bit_clmul_in.op     = clmul_issue0 ? eu_in.int_issue0.bit_op.bit_zbc
                                               : eu_in.int_issue1.bit_op.bit_zbc;

    eu_out.csr_alu0_in.cdata = eu_in.csr.cdata;
    eu_out.csr_alu0_in.rdata1 = eu_in.int_issue0.rdata1;
    eu_out.csr_alu0_in.imm = eu_in.int_issue0.imm;
    eu_out.csr_alu0_in.sel    = eu_in.int_issue0.csr_op.csrrwi | eu_in.int_issue0.csr_op.csrrsi | eu_in.int_issue0.csr_op.csrrci;
    eu_out.csr_alu0_in.csr_op = eu_in.int_issue0.csr_op;

    eu_out.csr_alu1_in.cdata = eu_in.csr.cdata;
    eu_out.csr_alu1_in.rdata1 = eu_in.int_issue1.rdata1;
    eu_out.csr_alu1_in.imm = eu_in.int_issue1.imm;
    eu_out.csr_alu1_in.sel    = eu_in.int_issue1.csr_op.csrrwi | eu_in.int_issue1.csr_op.csrrsi | eu_in.int_issue1.csr_op.csrrci;
    eu_out.csr_alu1_in.csr_op = eu_in.int_issue1.csr_op;

    eu0_result = eu_result(
      eu_in.int_issue0,
      eu_in.alu0_out.result,
      eu_in.agu0_out.address,
      eu_in.mul_out.result,
      eu_in.div_out.result,
      eu_in.bit_alu0_out.result,
      eu_in.csr.cdata,
      eu_in.bit_clmul_out.result
    );
    eu0_done =
        eu_done(eu_in.int_issue0, eu_in.int_issue0_valid, eu_in.div_out, eu_in.bit_clmul_out);

    eu1_result = eu_result(
      eu_in.int_issue1,
      eu_in.alu1_out.result,
      eu_in.agu1_out.address,
      eu_in.mul_out.result,
      eu_in.div_out.result,
      eu_in.bit_alu1_out.result,
      eu_in.csr.cdata,
      eu_in.bit_clmul_out.result
    );
    eu1_done =
        eu_done(eu_in.int_issue1, eu_in.int_issue1_valid, eu_in.div_out, eu_in.bit_clmul_out);

    mstore_data = store_data(
      eu_in.mem_store_issue.rdata2,
      eu_in.mem_store_issue.lsu_op.lsu_sb,
      eu_in.mem_store_issue.lsu_op.lsu_sh,
      eu_in.mem_store_issue.lsu_op.lsu_sw
    );

    if (!flush) begin

      if (r.div_pending_valid && eu_in.div_out.ready) begin
        if (r.div_pending.op.wren) begin
          v.cdb0.valid = 1'b1;
          v.cdb0.tag   = r.div_pending.pdest;
          v.cdb0.data  = eu_in.div_out.result;
        end
        v.rob_wtag0             = r.div_pending.rob_tag;
        v.rob_wen0              = 1'b1;
        v.rob_wentry0.done      = 1'b1;
        v.rob_wentry0.result    = eu_in.div_out.result;
        v.rob_wentry0.npc       = '0;
        v.rob_wentry0.branch    = 1'b0;
        v.rob_wentry0.jump      = 1'b0;
        v.rob_wentry0.exception = 1'b0;
        v.rob_wentry0.ecause    = '0;
        v.rob_wentry0.etval     = '0;
        v.rob_wentry0.cwdata    = '0;

      end else if (eu_in.int_issue0_valid && eu0_done) begin
        if (eu_in.int_issue0.op.wren) begin
          v.cdb0.valid = 1'b1;
          v.cdb0.tag   = eu_in.int_issue0.pdest;
          v.cdb0.data  = eu0_result;
        end
        v.rob_wen0 = 1'b1;
        v.rob_wentry0.done = 1'b1;
        v.rob_wentry0.result = eu0_result;
        v.rob_wentry0.npc = eu_in.agu0_out.address;
        v.rob_wentry0.branch = eu_in.int_issue0.op.branch;
        v.rob_wentry0.jump = eu_in.int_issue0.op.jal | eu_in.int_issue0.op.jalr | branch0_taken;
        v.rob_wentry0.exception = eu_in.int_issue0.op.ecall | eu_in.int_issue0.op.ebreak |
                                  eu_in.agu0_out.exception;
        v.rob_wentry0.ecause    = eu_in.int_issue0.op.ecall  ? except_env_call_user :
                                  eu_in.int_issue0.op.ebreak ? except_breakpoint    :
                                                               eu_in.agu0_out.ecause;
        v.rob_wentry0.etval = eu_in.agu0_out.etval;
        v.rob_wentry0.cwdata = eu_in.csr_alu0_out.cdata;
      end

      if (r.clmul_pending_valid && eu_in.bit_clmul_out.ready) begin
        if (r.clmul_pending.op.wren) begin
          v.cdb1.valid = 1'b1;
          v.cdb1.tag   = r.clmul_pending.pdest;
          v.cdb1.data  = eu_in.bit_clmul_out.result;
        end
        v.rob_wtag1             = r.clmul_pending.rob_tag;
        v.rob_wen1              = 1'b1;
        v.rob_wentry1.done      = 1'b1;
        v.rob_wentry1.result    = eu_in.bit_clmul_out.result;
        v.rob_wentry1.npc       = '0;
        v.rob_wentry1.branch    = 1'b0;
        v.rob_wentry1.jump      = 1'b0;
        v.rob_wentry1.exception = 1'b0;
        v.rob_wentry1.ecause    = '0;
        v.rob_wentry1.etval     = '0;
        v.rob_wentry1.cwdata    = '0;

      end else if (eu_in.int_issue1_valid && eu1_done) begin
        if (eu_in.int_issue1.op.wren) begin
          v.cdb1.valid = 1'b1;
          v.cdb1.tag   = eu_in.int_issue1.pdest;
          v.cdb1.data  = eu1_result;
        end
        v.rob_wen1 = 1'b1;
        v.rob_wentry1.done = 1'b1;
        v.rob_wentry1.result = eu1_result;
        v.rob_wentry1.npc = eu_in.agu1_out.address;
        v.rob_wentry1.branch = eu_in.int_issue1.op.branch;
        v.rob_wentry1.jump = eu_in.int_issue1.op.jal | eu_in.int_issue1.op.jalr | branch1_taken;
        v.rob_wentry1.exception = eu_in.int_issue1.op.ecall | eu_in.int_issue1.op.ebreak |
                                  eu_in.agu1_out.exception;
        v.rob_wentry1.ecause    = eu_in.int_issue1.op.ecall  ? except_env_call_user :
                                  eu_in.int_issue1.op.ebreak ? except_breakpoint    :
                                                               eu_in.agu1_out.ecause;
        v.rob_wentry1.etval = eu_in.agu1_out.etval;
        v.rob_wentry1.cwdata = eu_in.csr_alu1_out.cdata;
      end

      if (eu_in.mem_store_issue_valid) begin
        v.rob_wtag_store              = eu_in.mem_store_issue.rob_tag;
        v.rob_wen_store               = 1'b1;
        v.rob_wentry_store.done       = eu_in.mem_store_issue.op.store;
        v.rob_wentry_store.store_addr = eu_in.agu3_out.address;
        v.rob_wentry_store.store_data = mstore_data;
        v.rob_wentry_store.store_strb = eu_in.agu3_out.byteenable;
        v.rob_wentry_store.exception  = eu_in.agu3_out.exception;
        v.rob_wentry_store.ecause     = eu_in.agu3_out.ecause;
        v.rob_wentry_store.etval      = eu_in.agu3_out.etval;
      end

    end

    rin                     = v;

    eu_out.cdb0             = r.cdb0;
    eu_out.cdb1             = r.cdb1;
    eu_out.rob_wtag0        = r.rob_wtag0;
    eu_out.rob_wentry0      = r.rob_wentry0;
    eu_out.rob_wen0         = r.rob_wen0;
    eu_out.rob_wtag1        = r.rob_wtag1;
    eu_out.rob_wentry1      = r.rob_wentry1;
    eu_out.rob_wen1         = r.rob_wen1;
    eu_out.rob_wtag_store   = r.rob_wtag_store;
    eu_out.rob_wentry_store = r.rob_wentry_store;
    eu_out.rob_wen_store    = r.rob_wen_store;
    eu_out.div_busy         = r.div_pending_valid;
    eu_out.clmul_busy       = r.clmul_pending_valid;

  end

  always_ff @(posedge clock) begin
    if (reset == 0) begin
      r <= init_eu_reg;
    end else begin
      r <= rin;
    end
  end

endmodule
