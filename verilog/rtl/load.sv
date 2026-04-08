import configure::*;
import constants::*;
import wires::*;
import functions::*;

module load (
    input  logic         reset,
    input  logic         clock,
    input  load_in_type  load_in,
    output load_out_type load_out,
    input  logic         flush
);
  timeunit 1ns; timeprecision 1ps;

  agu_in_type  lagu_in;
  agu_out_type lagu_out;

  assign lagu_in.rdata1 = load_in.issue.rdata1;
  assign lagu_in.imm    = load_in.issue.imm;
  assign lagu_in.pc     = load_in.issue.pc;
  assign lagu_in.auipc  = 0;
  assign lagu_in.jal    = 0;
  assign lagu_in.jalr   = 0;
  assign lagu_in.branch = 0;
  assign lagu_in.load   = load_in.issue.op.load;
  assign lagu_in.store  = 0;
  assign lagu_in.lsu_op = load_in.issue.lsu_op;

  agu lagu_comp (
      .agu_in (lagu_in),
      .agu_out(lagu_out)
  );

  logic load_enable;
  assign load_enable                = load_in.issue_valid && load_in.issue.op.load && !flush;

  assign load_out.dmem_in.mem_valid = load_enable;
  assign load_out.dmem_in.mem_instr = 0;
  assign load_out.dmem_in.mem_mode  = 0;
  assign load_out.dmem_in.mem_addr  = lagu_out.address;
  assign load_out.dmem_in.mem_wdata = 0;
  assign load_out.dmem_in.mem_wstrb = 0;

  assign load_out.lsu_in.ldata      = load_in.dmem_out.mem_rdata;
  assign load_out.lsu_in.byteenable = lagu_out.byteenable;
  assign load_out.lsu_in.lsu_op     = load_in.issue.lsu_op;

  logic load_ready;
  assign load_ready = load_in.dmem_out.mem_ready && load_enable;

  always_comb begin
    load_out.cdb = init_cdb;
    load_out.rob_wtag   = load_in.issue.rob_tag;
    load_out.rob_wentry = init_rob_entry;
    load_out.rob_wen    = 0;

    if (load_ready && !flush) begin
      load_out.cdb.valid            = 1;
      load_out.cdb.tag              = load_in.issue.pdest;
      load_out.cdb.data             = load_in.lsu_out.result;
      load_out.rob_wen              = 1;
      load_out.rob_wentry.done      = 1;
      load_out.rob_wentry.result    = load_in.lsu_out.result;
      load_out.rob_wentry.exception = lagu_out.exception;
      load_out.rob_wentry.ecause    = lagu_out.ecause;
      load_out.rob_wentry.etval     = lagu_out.etval;
    end
  end

endmodule
