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
  commit_type ctrl;

  always_comb begin

    v                     = r;

    e0                    = commit_in.entry0;
    e1                    = commit_in.entry1;
    c0                    = commit_in.commit0;
    c1                    = commit_in.commit1;
    ctrl                  = commit_in.commit_ctrl;

    v.flush               = ctrl.flush;
    v.flush_pc            = ctrl.flush_pc;

    v.register0_win.wren  = c0 && e0.wren && !e0.exception;
    v.register0_win.waddr = e0.adest;
    v.register0_win.wdata = e0.result;

    v.register1_win.wren  = c1 && e1.wren && !e1.exception;
    v.register1_win.waddr = e1.adest;
    v.register1_win.wdata = e1.result;

    v.prf.wren0           = c0 && e0.wren && !e0.exception;
    v.prf.waddr0          = e0.pdest;
    v.prf.wdata0          = e0.result;
    v.prf.wren1           = c1 && e1.wren && !e1.exception;
    v.prf.waddr1          = e1.pdest;
    v.prf.wdata1          = e1.result;
    v.prf.raddr0          = '0;
    v.prf.raddr1          = '0;
    v.prf.raddr2          = '0;
    v.prf.raddr3          = '0;

    v.rat.commit_addr0    = e0.adest;
    v.rat.commit_tag0     = e0.pdest;
    v.rat.commit_en0      = c0 && e0.wren && !e0.exception;
    v.rat.commit_addr1    = e1.adest;
    v.rat.commit_tag1     = e1.pdest;
    v.rat.commit_en1      = c1 && e1.wren && !e1.exception;
    v.rat.rsrc0_a         = '0;
    v.rat.rsrc1_a         = '0;
    v.rat.rsrc2_a         = '0;
    v.rat.rsrc3_a         = '0;
    v.rat.waddr0_a        = '0;
    v.rat.waddr0_p        = '0;
    v.rat.wren0           = 1'b0;
    v.rat.waddr1_a        = '0;
    v.rat.waddr1_p        = '0;
    v.rat.wren1           = 1'b0;

    v.fl.free_tag0        = e0.old_pdest;
    v.fl.free_en0         = c0 && e0.wren;
    v.fl.free_tag1        = e1.old_pdest;
    v.fl.free_en1         = c1 && e1.wren;
    v.fl.alloc0           = 1'b0;
    v.fl.alloc1           = 1'b0;

    v.commit_store        = c0 && e0.store && !e0.exception;
    v.commit_entry        = e0;

    v.csr_win             = init_csr_write_in;
    v.csr_ein             = init_csr_exception_in;

    if (c0 && !e0.exception) begin
      if (e0.cwren) begin
        v.csr_win.cwren  = 1'b1;
        v.csr_win.cwaddr = e0.caddr;
        v.csr_win.cdata  = e0.cwdata;
      end
      if (e0.mret) begin
        v.csr_ein.valid0 = 1'b1;
        v.csr_ein.mret   = 1'b1;
        v.csr_ein.epc    = e0.pc;
      end
    end
    if (c0 && e0.exception) begin
      v.csr_ein.valid0    = 1'b1;
      v.csr_ein.exception = 1'b1;
      v.csr_ein.pc        = e0.pc;
      v.csr_ein.epc       = e0.pc;
      v.csr_ein.ecause    = e0.ecause;
      v.csr_ein.etval     = e0.etval;
    end
    if (c1 && e1.exception && !e0.exception) begin
      v.csr_ein.valid1    = 1'b1;
      v.csr_ein.exception = 1'b1;
      v.csr_ein.pc        = e1.pc;
      v.csr_ein.epc       = e1.pc;
      v.csr_ein.ecause    = e1.ecause;
      v.csr_ein.etval     = e1.etval;
    end

    rin                      = v;

    commit_out.register0_win = r.register0_win;
    commit_out.register1_win = r.register1_win;
    commit_out.csr_win       = r.csr_win;
    commit_out.csr_ein       = r.csr_ein;
    commit_out.rat           = r.rat;
    commit_out.prf           = r.prf;
    commit_out.fl            = r.fl;
    commit_out.flush         = r.flush;
    commit_out.flush_pc      = r.flush_pc;
    commit_out.commit_store  = r.commit_store;
    commit_out.commit_entry  = r.commit_entry;

  end

  always_ff @(posedge clock) begin
    if (reset == 0) begin
      r <= init_commit_reg;
    end else begin
      r <= rin;
    end
  end

endmodule
