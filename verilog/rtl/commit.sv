import configure::*;
import constants::*;
import wires::*;
import functions::*;
module commit (
    input  logic           reset,
    input  logic           clock,
    input  commit_in_type  commit_in,
    output commit_out_type commit_out
);
  timeunit 1ns; timeprecision 1ps;
  typedef struct packed {
    register_write_in_type register0_win;
    register_write_in_type register1_win;
    csr_write_in_type      csr_win;
    csr_exception_in_type  csr_ein;
    rat_in_type            rat_i;
    prf_in_type            prf_i;
    fl_in_type             fl_i;
    logic [0:0]            flush;
    logic [31:0]           flush_pc;
    logic [0:0]            commit_store;
    rob_entry_type         commit_entry;
  } commit_reg_type;
  localparam commit_reg_type init_commit_reg = '{
      register0_win : '{wren : 0, waddr : 0, wdata : 0},
      register1_win : '{wren : 0, waddr : 0, wdata : 0},
      csr_win       : init_csr_write_in,
      csr_ein       : init_csr_exception_in,
      rat_i         : init_rat_in,
      prf_i         : init_prf_in,
      fl_i          : init_fl_in,
      flush         : 0,
      flush_pc      : 0,
      commit_store  : 0,
      commit_entry  : init_rob_entry
  };
  commit_reg_type r, rin;
  commit_reg_type v;
  rob_entry_type e0, e1;
  logic c0, c1;
  logic flush0, flush1;
  logic [31:0] flush_pc0, flush_pc1;
  logic do0, do1;
  always_comb begin
    v = init_commit_reg;
    e0 = commit_in.entry0;
    e1 = commit_in.entry1;
    c0 = commit_in.commit0;
    c1 = commit_in.commit1;
    flush0 = 1'b0;
    flush1 = 1'b0;
    flush_pc0 = '0;
    flush_pc1 = '0;

    do0 = c0;

    if (do0) begin
      if (e0.exception) begin
        flush0 = 1'b1;
        flush_pc0 = commit_in.csr_o.mtvec;
      end else if (e0.mret) begin
        flush0 = 1'b1;
        flush_pc0 = commit_in.csr_o.mepc;
      end else if (e0.jump) begin
        flush0 = 1'b1;
        flush_pc0 = e0.npc;
      end
    end

    do1 = c1 && !flush0;

    if (do1) begin
      if (e1.exception) begin
        flush1 = 1'b1;
        flush_pc1 = commit_in.csr_o.mtvec;
      end else if (e1.mret) begin
        flush1 = 1'b1;
        flush_pc1 = commit_in.csr_o.mepc;
      end else if (e1.jump) begin
        flush1 = 1'b1;
        flush_pc1 = e1.npc;
      end
    end

    v.flush = flush0 | flush1;
    v.flush_pc = flush0 ? flush_pc0 : flush_pc1;

    if (do0 && e0.store) begin
      v.commit_store = 1'b1;
      v.commit_entry = e0;
    end
    if (do1 && e1.store) begin
      v.commit_store = 1'b1;
      v.commit_entry = e1;
    end

    if (do0) begin
      v.register0_win.wren = e0.wren;
      v.register0_win.waddr = e0.adest;
      v.register0_win.wdata = e0.result;
      v.prf_i.wren0 = e0.wren;
      v.prf_i.waddr0 = e0.pdest;
      v.prf_i.wdata0 = e0.result;
      v.rat_i.commit_addr0 = e0.adest;
      v.rat_i.commit_tag0 = e0.pdest;
      v.rat_i.commit_en0 = e0.wren;
      v.fl_i.free_tag0 = e0.old_pdest;
      v.fl_i.free_en0 = e0.wren;
    end
    if (do1) begin
      v.register1_win.wren = e1.wren;
      v.register1_win.waddr = e1.adest;
      v.register1_win.wdata = e1.result;
      v.prf_i.wren1 = e1.wren;
      v.prf_i.waddr1 = e1.pdest;
      v.prf_i.wdata1 = e1.result;
      v.rat_i.commit_addr1 = e1.adest;
      v.rat_i.commit_tag1 = e1.pdest;
      v.rat_i.commit_en1 = e1.wren;
      v.fl_i.free_tag1 = e1.old_pdest;
      v.fl_i.free_en1 = e1.wren;
    end

    if (do0 && e0.cwren) begin
      v.csr_win.cwren  = e0.cwren;
      v.csr_win.cwaddr = e0.caddr;
      v.csr_win.cdata  = e0.cwdata;
    end
    if (do1 && e1.cwren) begin
      v.csr_win.cwren  = e1.cwren;
      v.csr_win.cwaddr = e1.caddr;
      v.csr_win.cdata  = e1.cwdata;
    end

    if (do0) begin
      v.csr_ein.valid0 = 1'b1;
    end
    if (do1) begin
      v.csr_ein.valid1 = 1'b1;
    end

    if (do0) begin
      v.csr_ein.mret = e0.mret;
      v.csr_ein.exception = e0.exception;
      v.csr_ein.pc = e0.pc;
      v.csr_ein.epc = e0.pc;
      v.csr_ein.ecause = e0.ecause;
      v.csr_ein.etval = e0.etval;
    end
    if (do1) begin
      v.csr_ein.mret = e1.mret;
      v.csr_ein.exception = e1.exception;
      v.csr_ein.pc = e1.pc;
      v.csr_ein.epc = e1.pc;
      v.csr_ein.ecause = e1.ecause;
      v.csr_ein.etval = e1.etval;
    end

    if (r.flush) begin
      v = init_commit_reg;
    end

    rin = v;

    commit_out.register0_win = r.register0_win;
    commit_out.register1_win = r.register1_win;
    commit_out.csr_win = r.csr_win;
    commit_out.csr_ein = r.csr_ein;
    commit_out.rat_i = v.rat_i;
    commit_out.prf_i = v.prf_i;
    commit_out.fl_i = r.fl_i;
    commit_out.flush = r.flush;
    commit_out.flush_pc = r.flush_pc;
    commit_out.commit_store = r.commit_store;
    commit_out.commit_entry = r.commit_entry;
  end
  always_ff @(posedge clock) begin
    if (reset == 0) begin
      r <= init_commit_reg;
    end else begin
      r <= rin;
    end
  end
endmodule
