import configure::*;
import constants::*;
import wires::*;
import functions::*;

module msu (
  input  logic        reset,
  input  logic        clock,
  input  logic        flush,
  input  msu_in_type  msu_in,
  output msu_out_type msu_out
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
    mem_in_type               dmem1_in;
    lsu_in_type               lsu1_in;
    mem_in_type               dmem0_in;
    lsu_in_type               lsu0_in;
    logic [0:0]               load0_pending;
    logic [ROB_ADDR_BITS-1:0] load0_rob_tag;
    logic [PRF_ADDR_BITS-1:0] load0_pdest;
    logic [31:0]              load0_addr;
    logic [0:0]               load1_pending;
    logic [ROB_ADDR_BITS-1:0] load1_rob_tag;
    logic [PRF_ADDR_BITS-1:0] load1_pdest;
    logic [31:0]              load1_addr;
    logic [0:0]               store0_pending;
    logic [0:0]               store0_sent;
    rob_entry_type            store0_entry;
    logic [0:0]               store1_pending;
    logic [0:0]               store1_sent;
    rob_entry_type            store1_entry;
    logic [0:0]               load0_sent;
    logic [0:0]               load1_sent;
  } msu_reg_type;

  localparam msu_reg_type init_msu_reg = '{
      cdb0           : init_cdb,
      cdb1           : init_cdb,
      rob_wtag0      : '0,
      rob_wentry0    : init_rob_entry,
      rob_wen0       : 1'b0,
      rob_wtag1      : '0,
      rob_wentry1    : init_rob_entry,
      rob_wen1       : 1'b0,
      dmem1_in       : init_mem_in,
      lsu1_in        : '{ldata : 32'h0, byteenable : 4'h0, lsu_op : init_lsu_op},
      dmem0_in       : init_mem_in,
      lsu0_in        : '{ldata : 32'h0, byteenable : 4'h0, lsu_op : init_lsu_op},
      load0_pending  : 1'b0,
      load0_sent     : 1'b0,
      load0_rob_tag  : '0,
      load0_pdest    : '0,
      load0_addr     : '0,
      load1_pending  : 1'b0,
      load1_sent     : 1'b0,
      load1_rob_tag  : '0,
      load1_pdest    : '0,
      load1_addr     : '0,
      store0_pending : 1'b0,
      store0_sent    : 1'b0,
      store0_entry   : init_rob_entry,
      store1_pending : 1'b0,
      store1_sent    : 1'b0,
      store1_entry   : init_rob_entry
  };

  msu_reg_type r, rin, v;
  logic load0_accept, load1_accept;
  logic load0_ready, load1_ready;
  logic commit_store0_valid, commit_store1_valid;
  logic mem_pending_any;
  logic mem_block_new_issue;
  logic load0_busy, load1_busy, store0_busy, store1_busy;

  always_comb begin
    v = init_msu_reg;
    if (!flush) begin
      v = r;
    end

    v.lsu0_in.ldata = msu_in.dmem0_out.mem_rdata;
    v.lsu1_in.ldata = msu_in.dmem1_out.mem_rdata;

    commit_store0_valid = msu_in.commit_store0 && !msu_in.commit_entry0.exception && !flush;
    commit_store1_valid = msu_in.commit_store1 && !msu_in.commit_entry1.exception && !flush;

    load0_busy = r.load0_pending && !msu_in.dmem0_out.mem_ready;
    load1_busy = r.load1_pending && !msu_in.dmem1_out.mem_ready;
    store0_busy = r.store0_pending && !msu_in.dmem0_out.mem_ready;
    store1_busy = r.store1_pending && !msu_in.dmem1_out.mem_ready;
    mem_pending_any = load0_busy || load1_busy || store0_busy || store1_busy;
    mem_block_new_issue = mem_pending_any || commit_store0_valid || commit_store1_valid;

    load0_accept = msu_in.issue0_valid && msu_in.issue0.op.load && !mem_block_new_issue && !flush;
    load1_accept = msu_in.issue1_valid && msu_in.issue1.op.load && !mem_block_new_issue && !flush;
    load0_ready = r.load0_pending && !r.store0_pending && msu_in.dmem0_out.mem_ready && !flush;
    load1_ready = r.load1_pending && !r.store1_pending && msu_in.dmem1_out.mem_ready && !flush;

    if (load0_accept && !msu_in.agu2_out.exception) begin
      v.load0_pending      = 1'b1;
      v.load0_sent         = 1'b0;
      v.load0_rob_tag      = msu_in.issue0.rob_tag;
      v.load0_pdest        = msu_in.issue0.pdest;
      v.load0_addr         = msu_in.agu2_out.address;
      v.lsu0_in.byteenable = msu_in.agu2_out.byteenable;
      v.lsu0_in.lsu_op     = msu_in.issue0.lsu_op;
    end
    if (load1_accept && !msu_in.agu3_out.exception) begin
      v.load1_pending      = 1'b1;
      v.load1_sent         = 1'b0;
      v.load1_rob_tag      = msu_in.issue1.rob_tag;
      v.load1_pdest        = msu_in.issue1.pdest;
      v.load1_addr         = msu_in.agu3_out.address;
      v.lsu1_in.byteenable = msu_in.agu3_out.byteenable;
      v.lsu1_in.lsu_op     = msu_in.issue1.lsu_op;
    end

    if (!mem_pending_any) begin
      if (commit_store0_valid) begin
        v.store0_pending = 1'b1;
        v.store0_sent    = 1'b0;
        v.store0_entry   = msu_in.commit_entry0;
      end
      if (commit_store1_valid) begin
        if (!commit_store0_valid) begin
          v.store0_pending = 1'b1;
          v.store0_sent    = 1'b0;
          v.store0_entry   = msu_in.commit_entry1;
        end else begin
          v.store1_pending = 1'b1;
          v.store1_sent    = 1'b0;
          v.store1_entry   = msu_in.commit_entry1;
        end
      end
    end
    if (r.store0_pending && msu_in.dmem0_out.mem_ready && !flush) begin
      v.store0_pending = 1'b0;
      v.store0_sent    = 1'b0;
    end
    if (r.store1_pending && msu_in.dmem1_out.mem_ready && !flush) begin
      v.store1_pending = 1'b0;
      v.store1_sent    = 1'b0;
    end
    if (load0_ready) begin
      v.load0_pending = (load0_accept && !msu_in.agu2_out.exception) ? 1'b1 : 1'b0;
      v.load0_sent    = 1'b0;
    end
    if (load1_ready) begin
      v.load1_pending = (load1_accept && !msu_in.agu3_out.exception) ? 1'b1 : 1'b0;
      v.load1_sent    = 1'b0;
    end
    v.dmem0_in = init_mem_in;
    v.dmem1_in = init_mem_in;
    if (v.store0_pending && !v.store0_sent) begin
      v.dmem0_in.mem_valid = 1'b1;
      v.dmem0_in.mem_instr = 1'b0;
      v.dmem0_in.mem_mode  = 2'h0;
      v.dmem0_in.mem_addr  = v.store0_entry.store_addr;
      v.dmem0_in.mem_wdata = v.store0_entry.store_data;
      v.dmem0_in.mem_wstrb = v.store0_entry.store_strb;
      v.store0_sent        = 1'b1;
    end else if (v.load0_pending && !v.load0_sent) begin
      v.dmem0_in.mem_valid = 1'b1;
      v.dmem0_in.mem_instr = 1'b0;
      v.dmem0_in.mem_mode  = 2'h0;
      v.dmem0_in.mem_addr  = v.load0_addr;
      v.dmem0_in.mem_wdata = 32'h0;
      v.dmem0_in.mem_wstrb = 4'h0;
      v.load0_sent         = 1'b1;
    end
    if (v.store1_pending && !v.store1_sent) begin
      v.dmem1_in.mem_valid = 1'b1;
      v.dmem1_in.mem_instr = 1'b0;
      v.dmem1_in.mem_mode  = 2'h0;
      v.dmem1_in.mem_addr  = v.store1_entry.store_addr;
      v.dmem1_in.mem_wdata = v.store1_entry.store_data;
      v.dmem1_in.mem_wstrb = v.store1_entry.store_strb;
      v.store1_sent        = 1'b1;
    end else if (v.load1_pending && !v.load1_sent) begin
      v.dmem1_in.mem_valid = 1'b1;
      v.dmem1_in.mem_instr = 1'b0;
      v.dmem1_in.mem_mode  = 2'h0;
      v.dmem1_in.mem_addr  = v.load1_addr;
      v.dmem1_in.mem_wdata = 32'h0;
      v.dmem1_in.mem_wstrb = 4'h0;
      v.load1_sent         = 1'b1;
    end

    v.cdb0        = init_cdb;
    v.cdb1        = init_cdb;
    v.rob_wtag0   = r.load0_rob_tag;
    v.rob_wtag1   = r.load1_rob_tag;
    v.rob_wentry0 = init_rob_entry;
    v.rob_wentry1 = init_rob_entry;
    v.rob_wen0    = 1'b0;
    v.rob_wen1    = 1'b0;

    if (load0_accept && msu_in.agu2_out.exception) begin
      v.rob_wtag0             = msu_in.issue0.rob_tag;
      v.rob_wen0              = 1'b1;
      v.rob_wentry0.done      = 1'b1;
      v.rob_wentry0.exception = 1'b1;
      v.rob_wentry0.ecause    = msu_in.agu2_out.ecause;
      v.rob_wentry0.etval     = msu_in.agu2_out.etval;
    end else if (load0_ready) begin
      v.cdb0.valid         = 1'b1;
      v.cdb0.tag           = r.load0_pdest;
      v.cdb0.data          = msu_in.lsu0_out.result;
      v.rob_wen0           = 1'b1;
      v.rob_wentry0.done   = 1'b1;
      v.rob_wentry0.result = msu_in.lsu0_out.result;
      v.load0_pending      = (load0_accept && !msu_in.agu2_out.exception) ? 1'b1 : 1'b0;
      v.load0_sent         = 1'b0;
    end
    if (load1_accept && msu_in.agu3_out.exception) begin
      v.rob_wtag1             = msu_in.issue1.rob_tag;
      v.rob_wen1              = 1'b1;
      v.rob_wentry1.done      = 1'b1;
      v.rob_wentry1.exception = 1'b1;
      v.rob_wentry1.ecause    = msu_in.agu3_out.ecause;
      v.rob_wentry1.etval     = msu_in.agu3_out.etval;
    end else if (load1_ready) begin
      v.cdb1.valid         = 1'b1;
      v.cdb1.tag           = r.load1_pdest;
      v.cdb1.data          = msu_in.lsu1_out.result;
      v.rob_wen1           = 1'b1;
      v.rob_wentry1.done   = 1'b1;
      v.rob_wentry1.result = msu_in.lsu1_out.result;
      v.load1_pending      = (load1_accept && !msu_in.agu3_out.exception) ? 1'b1 : 1'b0;
      v.load1_sent         = 1'b0;
    end

    rin = v;

    msu_out.cdb0 = r.cdb0;
    msu_out.cdb1 = r.cdb1;
    msu_out.rob_wtag0 = r.rob_wtag0;
    msu_out.rob_wentry0 = r.rob_wentry0;
    msu_out.rob_wen0 = r.rob_wen0;
    msu_out.rob_wtag1 = r.rob_wtag1;
    msu_out.rob_wentry1 = r.rob_wentry1;
    msu_out.rob_wen1 = r.rob_wen1;
    msu_out.load_busy = {mem_block_new_issue, mem_block_new_issue};
    msu_out.store_ready = !(r.store0_pending || r.store1_pending) && !(msu_in.commit_store0 || msu_in.commit_store1);
    msu_out.dmem1_in = rin.dmem1_in;
    msu_out.lsu1_in = rin.lsu1_in;
    msu_out.dmem0_in = rin.dmem0_in;
    msu_out.lsu0_in = rin.lsu0_in;
    if (load0_ready) begin
      msu_out.lsu0_in.byteenable = r.lsu0_in.byteenable;
      msu_out.lsu0_in.lsu_op     = r.lsu0_in.lsu_op;
    end
    if (load1_ready) begin
      msu_out.lsu1_in.byteenable = r.lsu1_in.byteenable;
      msu_out.lsu1_in.lsu_op     = r.lsu1_in.lsu_op;
    end
  end

  always_ff @(posedge clock) begin
    if (reset == 0) begin
      r <= init_msu_reg;
    end else begin
      r <= rin;
    end
  end
endmodule
