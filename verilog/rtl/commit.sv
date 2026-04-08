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

  rob_entry_type e0, e1;
  logic c0, c1;
  commit_type ctrl;

  assign e0                             = commit_in.entry0;
  assign e1                             = commit_in.entry1;
  assign c0                             = commit_in.commit0;
  assign c1                             = commit_in.commit1;
  assign ctrl                           = commit_in.commit_ctrl;

  assign commit_out.flush               = ctrl.flush;
  assign commit_out.flush_pc            = ctrl.flush_pc;

  assign commit_out.register0_win.wren  = c0 && e0.wren && !e0.exception;
  assign commit_out.register0_win.waddr = e0.adest;
  assign commit_out.register0_win.wdata = e0.result;

  assign commit_out.register1_win.wren  = c1 && e1.wren && !e1.exception;
  assign commit_out.register1_win.waddr = e1.adest;
  assign commit_out.register1_win.wdata = e1.result;

  assign commit_out.prf.wren0           = c0 && e0.wren && !e0.exception;
  assign commit_out.prf.waddr0          = e0.pdest;
  assign commit_out.prf.wdata0          = e0.result;
  assign commit_out.prf.wren1           = c1 && e1.wren && !e1.exception;
  assign commit_out.prf.waddr1          = e1.pdest;
  assign commit_out.prf.wdata1          = e1.result;
  assign commit_out.prf.raddr0          = '0;
  assign commit_out.prf.raddr1          = '0;
  assign commit_out.prf.raddr2          = '0;
  assign commit_out.prf.raddr3          = '0;

  assign commit_out.rat.commit_addr0    = e0.adest;
  assign commit_out.rat.commit_tag0     = e0.pdest;
  assign commit_out.rat.commit_en0      = c0 && e0.wren && !e0.exception;
  assign commit_out.rat.commit_addr1    = e1.adest;
  assign commit_out.rat.commit_tag1     = e1.pdest;
  assign commit_out.rat.commit_en1      = c1 && e1.wren && !e1.exception;
  assign commit_out.rat.rsrc0_a         = '0;
  assign commit_out.rat.rsrc1_a         = '0;
  assign commit_out.rat.rsrc2_a         = '0;
  assign commit_out.rat.rsrc3_a         = '0;
  assign commit_out.rat.waddr0_a        = '0;
  assign commit_out.rat.waddr0_p        = '0;
  assign commit_out.rat.wren0           = 0;
  assign commit_out.rat.waddr1_a        = '0;
  assign commit_out.rat.waddr1_p        = '0;
  assign commit_out.rat.wren1           = 0;

  assign commit_out.fl.free_tag0        = e0.old_pdest;
  assign commit_out.fl.free_en0         = c0 && e0.wren;
  assign commit_out.fl.free_tag1        = e1.old_pdest;
  assign commit_out.fl.free_en1         = c1 && e1.wren;
  assign commit_out.fl.alloc0           = 0;
  assign commit_out.fl.alloc1           = 0;

  assign commit_out.dmem_in.mem_valid   = c0 && e0.store && !e0.exception;
  assign commit_out.dmem_in.mem_instr   = 0;
  assign commit_out.dmem_in.mem_mode    = 0;
  assign commit_out.dmem_in.mem_addr    = e0.store_addr;
  assign commit_out.dmem_in.mem_wdata   = e0.store_data;
  assign commit_out.dmem_in.mem_wstrb   = e0.store_strb;

  assign commit_out.lsu_in.ldata        = commit_in.dmem_out.mem_rdata;
  assign commit_out.lsu_in.byteenable   = e0.store_strb;
  assign commit_out.lsu_in.lsu_op       = e0.lsu_op;

  always_comb begin
    commit_out.csr_win = '{cwren: 0, cwaddr: 0, cdata: 0};
    commit_out.csr_ein = '{
        valid0: 0,
        valid1: 0,
        pc: 0,
        mret: 0,
        exception: 0,
        epc: 0,
        ecause: 0,
        etval: 0
    };

    if (c0 && !e0.exception) begin
      if (e0.cwren) begin
        commit_out.csr_win.cwren  = 1;
        commit_out.csr_win.cwaddr = e0.caddr;
        commit_out.csr_win.cdata  = e0.cwdata;
      end
      if (e0.mret) begin
        commit_out.csr_ein.valid0 = 1;
        commit_out.csr_ein.mret   = 1;
        commit_out.csr_ein.epc    = e0.pc;
      end
    end
    if (c0 && e0.exception) begin
      commit_out.csr_ein.valid0    = 1;
      commit_out.csr_ein.exception = 1;
      commit_out.csr_ein.pc        = e0.pc;
      commit_out.csr_ein.epc       = e0.pc;
      commit_out.csr_ein.ecause    = e0.ecause;
      commit_out.csr_ein.etval     = e0.etval;
    end
    if (c1 && e1.exception && !e0.exception) begin
      commit_out.csr_ein.valid1    = 1;
      commit_out.csr_ein.exception = 1;
      commit_out.csr_ein.pc        = e1.pc;
      commit_out.csr_ein.epc       = e1.pc;
      commit_out.csr_ein.ecause    = e1.ecause;
      commit_out.csr_ein.etval     = e1.etval;
    end
  end

endmodule
