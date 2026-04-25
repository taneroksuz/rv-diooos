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
    cdb_type                  cdb;
    logic [ROB_ADDR_BITS-1:0] rob_wtag;
    rob_entry_type            rob_wentry;
    logic [0:0]               rob_wen;
    mem_in_type               dmem1_in;
    lsu_in_type               lsu1_in;
    mem_in_type               dmem0_in;
    lsu_in_type               lsu0_in;
    logic [0:0]               load_pending;
    logic [ROB_ADDR_BITS-1:0] load_rob_tag;
    logic [PRF_ADDR_BITS-1:0] load_pdest;
    logic [31:0]              load_addr;
    logic [31:0]              load_etval;
    logic [7:0]               load_ecause;
    logic [0:0]               load_exception;
    logic [7:0]               load_wait_ctr;
    logic [0:0]               store_pending;
    logic [0:0]               store_sent;
    rob_entry_type            store_entry;
  } msu_reg_type;

  localparam msu_reg_type init_msu_reg = '{
      cdb            : init_cdb,
      rob_wtag       : '0,
      rob_wentry     : init_rob_entry,
      rob_wen        : 1'b0,
      dmem1_in       : init_mem_in,
      lsu1_in        : '{ldata : 32'h0, byteenable : 4'h0, lsu_op : init_lsu_op},
      dmem0_in       : init_mem_in,
      lsu0_in        : '{ldata : 32'h0, byteenable : 4'h0, lsu_op : init_lsu_op},
      load_pending   : 1'b0,
      load_rob_tag   : '0,
      load_pdest     : '0,
      load_addr      : '0,
      load_etval     : '0,
      load_ecause    : '0,
      load_exception : 1'b0,
      load_wait_ctr  : '0,
      store_pending  : 1'b0,
      store_sent     : 1'b0,
      store_entry    : init_rob_entry
  };

  msu_reg_type r, rin, v;
  logic load_accept;
  logic load_ready;
  logic load_retry;
  lsu_in_type lsu1_in_cur;

  always_comb begin
    v = init_msu_reg;
    if (!flush) begin
      v = r;
    end

    load_accept          = msu_in.issue_valid && msu_in.issue.op.load && !flush && !r.load_pending;
    load_ready           = r.load_pending && msu_in.dmem1_out.mem_ready && !flush;
    load_retry           = r.load_pending && !load_ready && (r.load_wait_ctr == 8'h40) && !flush;

    lsu1_in_cur          = r.lsu1_in;
    lsu1_in_cur.ldata    = msu_in.dmem1_out.mem_rdata;

    v.dmem1_in           = init_mem_in;
    v.dmem1_in.mem_valid = (load_accept && !msu_in.agu2_out.exception) || load_retry;
    v.dmem1_in.mem_instr = 1'b0;
    v.dmem1_in.mem_mode  = 2'h0;
    v.dmem1_in.mem_addr  = load_accept ? msu_in.agu2_out.address : r.load_addr;
    v.dmem1_in.mem_wdata = 32'h0;
    v.dmem1_in.mem_wstrb = 4'h0;

    if (load_accept && !msu_in.agu2_out.exception) begin
      v.lsu1_in.ldata      = 32'h0;
      v.lsu1_in.byteenable = msu_in.agu2_out.byteenable;
      v.lsu1_in.lsu_op     = msu_in.issue.lsu_op;
      v.load_pending       = 1'b1;
      v.load_rob_tag       = msu_in.issue.rob_tag;
      v.load_pdest         = msu_in.issue.pdest;
      v.load_addr          = msu_in.agu2_out.address;
      v.load_exception     = 1'b0;
      v.load_ecause        = '0;
      v.load_etval         = '0;
      v.load_wait_ctr      = '0;
    end

    if (r.load_pending && !load_ready) begin
      if (load_retry) begin
        v.load_wait_ctr = '0;
      end else begin
        v.load_wait_ctr = r.load_wait_ctr + 8'h1;
      end
    end

    v.dmem0_in = init_mem_in;
    if (!r.store_pending && msu_in.commit_store && !msu_in.commit_entry.exception && !flush) begin
      v.store_pending = 1'b1;
      v.store_sent    = 1'b0;
      v.store_entry   = msu_in.commit_entry;
    end
    if (r.store_pending && msu_in.dmem0_out.mem_ready && !flush) begin
      v.store_pending = 1'b0;
      v.store_sent    = 1'b0;
    end
    v.dmem0_in.mem_valid = r.store_pending;
    v.dmem0_in.mem_instr = 1'b0;
    v.dmem0_in.mem_mode  = 2'h0;
    v.dmem0_in.mem_addr  = r.store_entry.store_addr;
    v.dmem0_in.mem_wdata = r.store_entry.store_data;
    v.dmem0_in.mem_wstrb = r.store_entry.store_strb;

    v.lsu0_in.ldata      = msu_in.dmem0_out.mem_rdata;
    v.lsu0_in.byteenable = r.store_entry.store_strb;
    v.lsu0_in.lsu_op     = r.store_entry.lsu_op;

    v.cdb                = init_cdb;
    v.rob_wtag           = r.load_rob_tag;
    v.rob_wentry         = init_rob_entry;
    v.rob_wen            = 1'b0;

    if (load_accept && msu_in.agu2_out.exception) begin
      v.rob_wtag             = msu_in.issue.rob_tag;
      v.rob_wen              = 1'b1;
      v.rob_wentry.done      = 1'b1;
      v.rob_wentry.result    = 32'h0;
      v.rob_wentry.exception = 1'b1;
      v.rob_wentry.ecause    = msu_in.agu2_out.ecause;
      v.rob_wentry.etval     = msu_in.agu2_out.etval;
    end else if (load_ready) begin
      v.cdb.valid            = 1'b1;
      v.cdb.tag              = r.load_pdest;
      v.cdb.data             = msu_in.lsu1_out.result;
      v.rob_wtag             = r.load_rob_tag;
      v.rob_wen              = 1'b1;
      v.rob_wentry.done      = 1'b1;
      v.rob_wentry.result    = msu_in.lsu1_out.result;
      v.rob_wentry.exception = r.load_exception;
      v.rob_wentry.ecause    = r.load_ecause;
      v.rob_wentry.etval     = r.load_etval;
      v.load_pending         = 1'b0;
      v.load_wait_ctr        = '0;
    end

    rin                 = v;

    msu_out.cdb         = r.cdb;
    msu_out.rob_wtag    = r.rob_wtag;
    msu_out.rob_wentry  = r.rob_wentry;
    msu_out.rob_wen     = r.rob_wen;
    msu_out.load_busy   = r.load_pending;
    msu_out.store_ready = !r.store_pending && !msu_in.commit_store;
    msu_out.dmem1_in    = rin.dmem1_in;
    msu_out.lsu1_in     = load_ready ? lsu1_in_cur : rin.lsu1_in;
    msu_out.dmem0_in    = rin.dmem0_in;
    msu_out.lsu0_in     = rin.lsu0_in;
  end

  always_ff @(posedge clock) begin
    if (reset == 0) begin
      r <= init_msu_reg;
    end else begin
      r <= rin;
    end
  end
endmodule
