import configure::*;
import constants::*;
import wires::*;

module cpu (
    input  logic               reset,
    input  logic               clock,
    input  mem_out_type        imem0_out,
    input  mem_out_type        imem1_out,
    output mem_in_type         imem0_in,
    output mem_in_type         imem1_in,
    input  mem_out_type        dmem0_out,
    input  mem_out_type        dmem1_out,
    output mem_in_type         dmem0_in,
    output mem_in_type         dmem1_in,
    input  logic        [ 0:0] meip,
    input  logic        [ 0:0] msip,
    input  logic        [ 0:0] mtip,
    input  logic        [63:0] mtime
);
  timeunit 1ns; timeprecision 1ps;

  cpu_ctrl_type cpu_ctrl;

  cdb_type cdb0, cdb1, cdb_load;
  csr_read_in_type csr_rin;

  alu_in_type alu0_in, alu1_in;
  alu_out_type alu0_out, alu1_out;
  bcu_in_type bcu0_in, bcu1_in;
  bcu_out_type bcu0_out, bcu1_out;
  mul_in_type  mul_in;
  mul_out_type mul_out;
  div_in_type  div_in;
  div_out_type div_out;
  bit_alu_in_type bit_alu0_in, bit_alu1_in;
  bit_alu_out_type bit_alu0_out, bit_alu1_out;
  bit_clmul_in_type  bit_clmul_in;
  bit_clmul_out_type bit_clmul_out;
  csr_alu_in_type    csr_alu_in;
  csr_alu_out_type   csr_alu_out;
  lsu_in_type lsu0_in, lsu1_in;
  lsu_out_type lsu0_out, lsu1_out;
  csr_out_type csr_out;

  agu_in_type agu0_in, agu1_in, agu2_in, agu3_in;
  agu_out_type agu0_out, agu1_out, agu2_out, agu3_out;

  register_write_in_type register0_win, register1_win;

  btac_in_type    btac_in;
  btac_out_type   btac_out;
  buffer_in_type  buffer_in;
  buffer_out_type buffer_out;
  compress_in_type compress0_in, compress1_in;
  compress_out_type compress0_out, compress1_out;
  decoder_in_type decoder0_in, decoder1_in;
  decoder_out_type decoder0_out, decoder1_out;

  ifetch_in_type   ifetch_in;
  ifetch_out_type  ifetch_out;
  idecode_in_type  idecode_in;
  idecode_out_type idecode_out;
  prf_in_type      prf_in;
  prf_out_type     prf_out;
  fl_in_type       fl_in;
  fl_out_type      fl_out;
  rat_in_type      rat_in;
  rat_out_type     rat_out;
  rob_in_type      rob_in;
  rob_out_type     rob_out;
  rs_int_in_type   rs_int_in;
  rs_int_out_type  rs_int_out;
  rs_mem_in_type   rs_mem_in;
  rs_mem_out_type  rs_mem_out;
  rename_in_type   rename_in;
  rename_out_type  rename_out;
  eu_in_type       eu_in;
  eu_out_type      eu_out;
  msu_in_type      msu_in;
  msu_out_type     msu_out;
  commit_in_type   commit_in;
  commit_out_type  commit_out;

  assign cpu_ctrl.flush = commit_out.flush;
  assign cpu_ctrl.flush_all = cpu_ctrl.flush | csr_out.trap | csr_out.mret;
  assign cpu_ctrl.flush_pc = csr_out.trap ? csr_out.mtvec :
                             csr_out.mret ? csr_out.mepc  :
                             commit_out.flush_pc;
  assign cpu_ctrl.backend_stall = rename_out.stall | rob_out.full;

  assign ifetch_in.csr_out = csr_out;
  assign ifetch_in.btac_out = btac_out;
  assign ifetch_in.imem0_out = imem0_out;
  assign ifetch_in.imem1_out = imem1_out;
  assign ifetch_in.buffer_out = buffer_out;

  assign buffer_in = ifetch_out.buffer_in;
  assign btac_in = ifetch_out.btac_in;
  assign imem0_in = ifetch_out.imem0_in;
  assign imem1_in = ifetch_out.imem1_in;

  assign csr_rin.crden  = (rs_int_out.issue0_valid && rs_int_out.issue0.op.csreg) ||
                          (rs_int_out.issue1_valid && rs_int_out.issue1.op.csreg);
  assign csr_rin.craddr = rs_int_out.issue0.op.csreg ? rs_int_out.issue0.caddr
                                                      : rs_int_out.issue1.caddr;

  assign idecode_in.decoder0_out = decoder0_out;
  assign idecode_in.decoder1_out = decoder1_out;
  assign idecode_in.compress0_out = compress0_out;
  assign idecode_in.compress1_out = compress1_out;
  assign idecode_in.pc0 = ifetch_out.pc0;
  assign idecode_in.pc1 = ifetch_out.pc1;
  assign idecode_in.instr0 = ifetch_out.instr0;
  assign idecode_in.instr1 = ifetch_out.instr1;
  assign idecode_in.ready0 = ifetch_out.ready0;
  assign idecode_in.ready1 = ifetch_out.ready1;

  assign decoder0_in = idecode_out.decoder0_in;
  assign decoder1_in = idecode_out.decoder1_in;
  assign compress0_in = idecode_out.compress0_in;
  assign compress1_in = idecode_out.compress1_in;

  assign prf_in.raddr0 = rat_out.psrc0;
  assign prf_in.raddr1 = rat_out.psrc1;
  assign prf_in.raddr2 = rat_out.psrc2;
  assign prf_in.raddr3 = rat_out.psrc3;
  assign prf_in.waddr0 = commit_out.prf.waddr0;
  assign prf_in.wdata0 = commit_out.prf.wdata0;
  assign prf_in.wren0 = commit_out.prf.wren0;
  assign prf_in.waddr1 = commit_out.prf.waddr1;
  assign prf_in.wdata1 = commit_out.prf.wdata1;
  assign prf_in.wren1 = commit_out.prf.wren1;

  assign rat_in.rsrc0_a = rename_out.rat.rsrc0_a;
  assign rat_in.rsrc1_a = rename_out.rat.rsrc1_a;
  assign rat_in.rsrc2_a = rename_out.rat.rsrc2_a;
  assign rat_in.rsrc3_a = rename_out.rat.rsrc3_a;
  assign rat_in.waddr0_a = rename_out.rat.waddr0_a;
  assign rat_in.waddr0_p = rename_out.rat.waddr0_p;
  assign rat_in.wren0 = rename_out.rat.wren0;
  assign rat_in.waddr1_a = rename_out.rat.waddr1_a;
  assign rat_in.waddr1_p = rename_out.rat.waddr1_p;
  assign rat_in.wren1 = rename_out.rat.wren1;
  assign rat_in.commit_addr0 = commit_out.rat.commit_addr0;
  assign rat_in.commit_tag0 = commit_out.rat.commit_tag0;
  assign rat_in.commit_en0 = commit_out.rat.commit_en0;
  assign rat_in.commit_addr1 = commit_out.rat.commit_addr1;
  assign rat_in.commit_tag1 = commit_out.rat.commit_tag1;
  assign rat_in.commit_en1 = commit_out.rat.commit_en1;

  assign fl_in.alloc0 = rename_out.fl.alloc0;
  assign fl_in.alloc1 = rename_out.fl.alloc1;
  assign fl_in.free_tag0 = commit_out.fl.free_tag0;
  assign fl_in.free_en0 = commit_out.fl.free_en0;
  assign fl_in.free_tag1 = commit_out.fl.free_tag1;
  assign fl_in.free_en1 = commit_out.fl.free_en1;

  assign rob_in.alloc0 = rename_out.rob_alloc0;
  assign rob_in.alloc_entry0 = rename_out.rob_entry0;
  assign rob_in.alloc1 = rename_out.rob_alloc1;
  assign rob_in.alloc_entry1 = rename_out.rob_entry1;
  assign rob_in.write_tag0 = eu_out.rob_wtag0;
  assign rob_in.write_entry0 = eu_out.rob_wentry0;
  assign rob_in.write_en0 = eu_out.rob_wen0;
  assign rob_in.write_tag1 = eu_out.rob_wtag1;
  assign rob_in.write_entry1 = eu_out.rob_wentry1;
  assign rob_in.write_en1 = eu_out.rob_wen1;
  assign rob_in.write_tag2 = msu_out.rob_wtag;
  assign rob_in.write_entry2 = msu_out.rob_wentry;
  assign rob_in.write_en2 = msu_out.rob_wen;
  assign rob_in.cdb0 = cdb0;
  assign rob_in.cdb1 = cdb1;

  assign rs_int_in.entry0 = rename_out.rs_int_entry0;
  assign rs_int_in.alloc0 = rename_out.rs_int_alloc0;
  assign rs_int_in.entry1 = rename_out.rs_int_entry1;
  assign rs_int_in.alloc1 = rename_out.rs_int_alloc1;
  assign rs_int_in.cdb0 = cdb0;
  assign rs_int_in.cdb1 = cdb1;
  assign rs_int_in.cdb_load = cdb_load;

  assign rs_mem_in.entry0 = rename_out.rs_mem_entry0;
  assign rs_mem_in.alloc0 = rename_out.rs_mem_alloc0;
  assign rs_mem_in.entry1 = rename_out.rs_mem_entry1;
  assign rs_mem_in.alloc1 = rename_out.rs_mem_alloc1;
  assign rs_mem_in.cdb0 = cdb0;
  assign rs_mem_in.cdb1 = cdb1;
  assign rs_mem_in.cdb_load = cdb_load;
  assign rs_mem_in.rob_array = rob_out.array;
  assign rs_mem_in.rob_head = rob_out.head_ptr;

  assign rename_in.instr0 = idecode_out.instr0;
  assign rename_in.instr0_valid = idecode_out.instr0.op.valid;
  assign rename_in.instr1 = idecode_out.instr1;
  assign rename_in.instr1_valid = idecode_out.instr1.op.valid;
  assign rename_in.rob_tag0 = rob_out.alloc_tag0;
  assign rename_in.rob_tag1 = rob_out.alloc_tag1;
  assign rename_in.rob_full = rob_out.full;
  assign rename_in.rob_has_two = rob_out.has_two_free;
  assign rename_in.rat = rat_out;
  assign rename_in.prf = prf_out;
  assign rename_in.fl = fl_out;
  assign rename_in.rs_int_full = rs_int_out.full;
  assign rename_in.rs_int_has_two = rs_int_out.has_two_free;
  assign rename_in.rs_mem_full = rs_mem_out.full;
  assign rename_in.rs_mem_has_two = rs_mem_out.has_two_free;
  assign rename_in.cdb0 = cdb0;
  assign rename_in.cdb1 = cdb1;
  assign rename_in.cdb_load = cdb_load;

  assign eu_in.int_issue0 = rs_int_out.issue0;
  assign eu_in.int_issue0_valid = rs_int_out.issue0_valid;
  assign eu_in.int_issue1 = rs_int_out.issue1;
  assign eu_in.int_issue1_valid = rs_int_out.issue1_valid;

  assign eu_in.mem_issue0 = rs_mem_out.issue0;
  assign eu_in.mem_issue0_valid = rs_mem_out.issue0_valid && rs_mem_out.issue0.op.store;
  assign eu_in.csr = csr_out;
  assign eu_in.alu0_out = alu0_out;
  assign eu_in.alu1_out = alu1_out;
  assign eu_in.agu0_out = agu0_out;
  assign eu_in.agu1_out = agu1_out;
  assign eu_in.agu2_out = agu2_out;
  assign eu_in.agu3_out = agu3_out;
  assign eu_in.bcu0_out = bcu0_out;
  assign eu_in.bcu1_out = bcu1_out;
  assign eu_in.mul_out = mul_out;
  assign eu_in.div_out = div_out;
  assign eu_in.bit_alu0_out = bit_alu0_out;
  assign eu_in.bit_alu1_out = bit_alu1_out;
  assign eu_in.bit_clmul_out = bit_clmul_out;
  assign eu_in.csr_alu_out = csr_alu_out;

  assign alu0_in = eu_out.alu0_in;
  assign alu1_in = eu_out.alu1_in;
  assign bcu0_in = eu_out.bcu0_in;
  assign bcu1_in = eu_out.bcu1_in;
  assign mul_in = eu_out.mul_in;
  assign div_in = eu_out.div_in;
  assign bit_alu0_in = eu_out.bit_alu0_in;
  assign bit_alu1_in = eu_out.bit_alu1_in;
  assign bit_clmul_in = eu_out.bit_clmul_in;
  assign csr_alu_in = eu_out.csr_alu_in;
  assign cdb0 = eu_out.cdb0;
  assign cdb1 = eu_out.cdb1;

  assign agu0_in = eu_out.agu0_in;
  assign agu1_in = eu_out.agu1_in;
  assign agu2_in = eu_out.agu2_in;
  assign agu3_in = eu_out.agu3_in;

  assign msu_in.issue = rs_mem_out.issue0;
  assign msu_in.issue_valid = rs_mem_out.issue0_valid && rs_mem_out.issue0.op.load;
  assign msu_in.agu2_out = agu2_out;
  assign msu_in.lsu1_out = lsu1_out;
  assign msu_in.dmem1_out = dmem1_out;
  assign msu_in.commit_store = commit_out.commit_store;
  assign msu_in.commit_entry = commit_out.commit_entry;
  assign msu_in.lsu0_out = lsu0_out;
  assign msu_in.dmem0_out = dmem0_out;

  assign dmem1_in = msu_out.dmem1_in;
  assign lsu1_in = msu_out.lsu1_in;
  assign dmem0_in = msu_out.dmem0_in;
  assign lsu0_in = msu_out.lsu0_in;
  assign cdb_load = msu_out.cdb;

  assign commit_in.commit0 = rob_out.commit0;
  assign commit_in.commit1 = rob_out.commit1;
  assign commit_in.commit_ctrl = rob_out.commit_ctrl;
  assign commit_in.entry0 = rob_out.entry0;
  assign commit_in.entry1 = rob_out.entry1;
  assign commit_in.csr = csr_out;

  assign register0_win = commit_out.register0_win;
  assign register1_win = commit_out.register1_win;

  alu alu0_comp (
      .alu_in (alu0_in),
      .alu_out(alu0_out)
  );
  alu alu1_comp (
      .alu_in (alu1_in),
      .alu_out(alu1_out)
  );

  agu agu0_comp (
      .agu_in (agu0_in),
      .agu_out(agu0_out)
  );

  agu agu1_comp (
      .agu_in (agu1_in),
      .agu_out(agu1_out)
  );

  agu agu2_comp (
      .agu_in (agu2_in),
      .agu_out(agu2_out)
  );

  agu agu3_comp (
      .agu_in (agu3_in),
      .agu_out(agu3_out)
  );

  bcu bcu0_comp (
      .bcu_in (bcu0_in),
      .bcu_out(bcu0_out)
  );
  bcu bcu1_comp (
      .bcu_in (bcu1_in),
      .bcu_out(bcu1_out)
  );

  lsu lsu0_comp (
      .lsu_in (lsu0_in),
      .lsu_out(lsu0_out)
  );

  lsu lsu1_comp (
      .lsu_in (lsu1_in),
      .lsu_out(lsu1_out)
  );

  csr_alu csr_alu_comp (
      .csr_alu_in (csr_alu_in),
      .csr_alu_out(csr_alu_out)
  );

  mul mul_comp (
      .reset  (reset),
      .clock  (clock),
      .flush  (cpu_ctrl.flush_all),
      .mul_in (mul_in),
      .mul_out(mul_out)
  );
  div div_comp (
      .reset  (reset),
      .clock  (clock),
      .flush  (cpu_ctrl.flush_all),
      .div_in (div_in),
      .div_out(div_out)
  );

  bit_alu bit_alu0_comp (
      .bit_alu_in (bit_alu0_in),
      .bit_alu_out(bit_alu0_out)
  );
  bit_alu bit_alu1_comp (
      .bit_alu_in (bit_alu1_in),
      .bit_alu_out(bit_alu1_out)
  );

  bit_clmul bit_clmul_comp (
      .reset(reset),
      .clock(clock),
      .flush(cpu_ctrl.flush_all),
      .bit_clmul_in(bit_clmul_in),
      .bit_clmul_out(bit_clmul_out)
  );

  btac btac_comp (
      .reset(reset),
      .clock(clock),
      .btac_in(btac_in),
      .btac_out(btac_out)
  );

  buffer buffer_comp (
      .reset(reset),
      .clock(clock),
      .buffer_in(buffer_in),
      .buffer_out(buffer_out)
  );

  decoder decoder0_comp (
      .decoder_in (decoder0_in),
      .decoder_out(decoder0_out)
  );
  decoder decoder1_comp (
      .decoder_in (decoder1_in),
      .decoder_out(decoder1_out)
  );

  compress compress0_comp (
      .compress_in (compress0_in),
      .compress_out(compress0_out)
  );
  compress compress1_comp (
      .compress_in (compress1_in),
      .compress_out(compress1_out)
  );

  register register_comp (
      .reset(reset),
      .clock(clock),
      .register0_rin('0),
      .register1_rin('0),
      .register0_win(register0_win),
      .register1_win(register1_win),
      .register0_out(),
      .register1_out()
  );

  csr csr_comp (
      .reset(reset),
      .clock(clock),
      .csr_rin(csr_rin),
      .csr_win(commit_out.csr_win),
      .csr_ein(commit_out.csr_ein),
      .csr_out(csr_out),
      .meip(meip),
      .msip(msip),
      .mtip(mtip),
      .mtime(mtime)
  );

  ifetch ifetch_comp (
      .reset(reset),
      .clock(clock),
      .flush(cpu_ctrl.flush_all),
      .stall(cpu_ctrl.backend_stall),
      .flush_pc(cpu_ctrl.flush_pc),
      .ifetch_in(ifetch_in),
      .ifetch_out(ifetch_out)
  );

  idecode idecode_comp (
      .reset(reset),
      .clock(clock),
      .flush(cpu_ctrl.flush_all),
      .idecode_in(idecode_in),
      .idecode_out(idecode_out)
  );

  prf prf_comp (
      .reset  (reset),
      .clock  (clock),
      .flush  (cpu_ctrl.flush_all),
      .prf_in (prf_in),
      .prf_out(prf_out)
  );

  rat rat_comp (
      .reset  (reset),
      .clock  (clock),
      .flush  (cpu_ctrl.flush_all),
      .rat_in (rat_in),
      .rat_out(rat_out)
  );

  fl fl_comp (
      .reset (reset),
      .clock (clock),
      .flush (cpu_ctrl.flush_all),
      .fl_in (fl_in),
      .fl_out(fl_out)
  );

  rob rob_comp (
      .reset  (reset),
      .clock  (clock),
      .flush  (cpu_ctrl.flush_all),
      .rob_in (rob_in),
      .rob_out(rob_out)
  );

  rs_int rs_int_comp (
      .reset (reset),
      .clock (clock),
      .flush (cpu_ctrl.flush_all),
      .rs_in (rs_int_in),
      .rs_out(rs_int_out)
  );

  rs_mem rs_mem_comp (
      .reset (reset),
      .clock (clock),
      .flush (cpu_ctrl.flush_all),
      .rs_in (rs_mem_in),
      .rs_out(rs_mem_out)
  );

  rename rename_comp (
      .reset(reset),
      .clock(clock),
      .flush(cpu_ctrl.flush_all),
      .rename_in(rename_in),
      .rename_out(rename_out)
  );

  eu eu_comp (
      .reset (reset),
      .clock (clock),
      .flush (cpu_ctrl.flush_all),
      .eu_in (eu_in),
      .eu_out(eu_out)
  );

  msu msu_comp (
      .reset  (reset),
      .clock  (clock),
      .flush  (cpu_ctrl.flush_all),
      .msu_in (msu_in),
      .msu_out(msu_out)
  );

  commit commit_comp (
      .reset(reset),
      .clock(clock),
      .commit_in(commit_in),
      .commit_out(commit_out)
  );

endmodule
