import configure::*;
import constants::*;
import wires::*;
import functions::*;

module ldu (
    input  logic        reset,
    input  logic        clock,
    input  logic        flush,
    input  ldu_in_type  ldu_in,
    output ldu_out_type ldu_out
);
  timeunit 1ns; timeprecision 1ps;

  agu_in_type  lagu_in;
  agu_out_type lagu_out;

  assign lagu_in.rdata1 = ldu_in.issue.rdata1;
  assign lagu_in.imm    = ldu_in.issue.imm;
  assign lagu_in.pc     = ldu_in.issue.pc;
  assign lagu_in.auipc  = 0;
  assign lagu_in.jal    = 0;
  assign lagu_in.jalr   = 0;
  assign lagu_in.branch = 0;
  assign lagu_in.load   = ldu_in.issue.op.load;
  assign lagu_in.store  = 0;
  assign lagu_in.lsu_op = ldu_in.issue.lsu_op;

  agu lagu_comp (
      .agu_in (lagu_in),
      .agu_out(lagu_out)
  );

  logic load_enable;
  assign load_enable               = ldu_in.issue_valid && ldu_in.issue.op.load && !flush;

  assign ldu_out.dmem_in.mem_valid = load_enable;
  assign ldu_out.dmem_in.mem_instr = 0;
  assign ldu_out.dmem_in.mem_mode  = 0;
  assign ldu_out.dmem_in.mem_addr  = lagu_out.address;
  assign ldu_out.dmem_in.mem_wdata = 0;
  assign ldu_out.dmem_in.mem_wstrb = 0;

  assign ldu_out.lsu_in.ldata      = ldu_in.dmem_out.mem_rdata;
  assign ldu_out.lsu_in.byteenable = lagu_out.byteenable;
  assign ldu_out.lsu_in.lsu_op     = ldu_in.issue.lsu_op;

  logic load_ready;
  assign load_ready = ldu_in.dmem_out.mem_ready && load_enable;

  always_comb begin
    ldu_out.cdb = init_cdb;
    ldu_out.rob_wtag   = ldu_in.issue.rob_tag;
    ldu_out.rob_wentry = init_rob_entry;
    ldu_out.rob_wen    = 0;

    if (load_ready && !flush) begin
      ldu_out.cdb.valid            = 1;
      ldu_out.cdb.tag              = ldu_in.issue.pdest;
      ldu_out.cdb.data             = ldu_in.lsu_out.result;
      ldu_out.rob_wen              = 1;
      ldu_out.rob_wentry.done      = 1;
      ldu_out.rob_wentry.result    = ldu_in.lsu_out.result;
      ldu_out.rob_wentry.exception = lagu_out.exception;
      ldu_out.rob_wentry.ecause    = lagu_out.ecause;
      ldu_out.rob_wentry.etval     = lagu_out.etval;
    end
  end

endmodule
