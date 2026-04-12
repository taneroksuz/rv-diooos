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
    rat_in_type            rat;
    prf_in_type            prf;
    fl_in_type             fl;
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
      rat           : init_rat_in,
      prf           : init_prf_in,
      fl            : init_fl_in,
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

    if (c0) begin
      if (e0.exception) begin
        flush0 = 1'b1;
        flush_pc0 = commit_in.csr.mtvec;
      end else if (e0.mret) begin
        flush0 = 1'b1;
        flush_pc0 = commit_in.csr.mepc;
      end else if (e0.jump && e0.npc != e0.pnpc) begin
        flush0 = 1'b1;
        flush_pc0 = e0.npc;
      end
    end

    if (c1 && !flush0) begin
      if (e1.exception) begin
        flush1 = 1'b1;
        flush_pc1 = commit_in.csr.mtvec;
      end else if (e1.mret) begin
        flush1 = 1'b1;
        flush_pc1 = commit_in.csr.mepc;
      end else if (e1.jump && e1.npc != e1.pnpc) begin
        flush1 = 1'b1;
        flush_pc1 = e1.npc;
      end
    end

    do0 = c0;
    do1 = c1 && !flush0;

    v.flush = flush0 | flush1;
    v.flush_pc = flush0 ? flush_pc0 : flush_pc1;

    v.commit_store = do0 && e0.store && !e0.exception && !flush0;
    v.commit_entry = e0;

    if (do0) begin
      v.register0_win.wren = e0.wren && !e0.exception;
      v.register0_win.waddr = e0.adest;
      v.register0_win.wdata = e0.result;
      v.prf.wren0 = e0.wren && !e0.exception;
      v.prf.waddr0 = e0.pdest;
      v.prf.wdata0 = e0.result;
      v.rat.commit_addr0 = e0.adest;
      v.rat.commit_tag0 = e0.pdest;
      v.rat.commit_en0 = e0.wren && !e0.exception;
      v.fl.free_tag0 = e0.old_pdest;
      v.fl.free_en0 = e0.wren;
      if (e0.cwren) begin
        v.csr_win.cwren  = 1'b1;
        v.csr_win.cwaddr = e0.caddr;
        v.csr_win.cdata  = e0.cwdata;
      end
      if (e0.mret) begin
        v.csr_ein.valid0 = 1'b1;
        v.csr_ein.mret = 1'b1;
        v.csr_ein.epc = e0.pc;
      end
      if (e0.exception) begin
        v.csr_ein.valid0 = 1'b1;
        v.csr_ein.exception = 1'b1;
        v.csr_ein.pc = e0.pc;
        v.csr_ein.epc = e0.pc;
        v.csr_ein.ecause = e0.ecause;
        v.csr_ein.etval = e0.etval;
      end
    end

    if (do1) begin
      v.register1_win.wren = e1.wren && !e1.exception;
      v.register1_win.waddr = e1.adest;
      v.register1_win.wdata = e1.result;
      v.prf.wren1 = e1.wren && !e1.exception;
      v.prf.waddr1 = e1.pdest;
      v.prf.wdata1 = e1.result;
      v.rat.commit_addr1 = e1.adest;
      v.rat.commit_tag1 = e1.pdest;
      v.rat.commit_en1 = e1.wren && !e1.exception;
      v.fl.free_tag1 = e1.old_pdest;
      v.fl.free_en1 = e1.wren;
      if (e1.exception) begin
        v.csr_ein.valid1 = 1'b1;
        v.csr_ein.exception = 1'b1;
        v.csr_ein.pc = e1.pc;
        v.csr_ein.epc = e1.pc;
        v.csr_ein.ecause = e1.ecause;
        v.csr_ein.etval = e1.etval;
      end
    end

    if (r.flush) begin
      v = init_commit_reg;
    end

    rin = v;
    commit_out.register0_win = r.register0_win;
    commit_out.register1_win = r.register1_win;
    commit_out.csr_win = r.csr_win;
    commit_out.csr_ein = r.csr_ein;
    commit_out.rat = r.rat;
    commit_out.prf = r.prf;
    commit_out.fl = r.fl;
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
