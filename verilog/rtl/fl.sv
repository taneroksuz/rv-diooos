import configure::*;
import wires::*;
import functions::*;

module fl (
    input  logic       reset,
    input  logic       clock,
    input  logic       flush,
    input  fl_in_type  fl_in,
    output fl_out_type fl_out
);
  timeunit 1ns; timeprecision 1ps;

  fl_reg_type r, rin;
  fl_reg_type v;

  logic [FL_CNT_BITS-1:0] nt, nsc, ncc, nsh, nch, sh1;

  always_comb begin

    nt  = '0;
    nsc = '0;
    ncc = '0;
    nsh = '0;
    nch = '0;
    sh1 = '0;

    v   = r;

    nt  = r.tail;
    nsc = r.spec_count;
    ncc = r.comm_count;
    nsh = r.spec_head;
    nch = r.comm_head;

    if (fl_in.free_en0) begin
      v.list = fl_write(v.list, nt[FL_IDX_BITS-1:0], fl_in.free_tag0);
      nt = nt + 1;
      ncc = ncc + 1;
      nsc = nsc + 1;
      nch = nch + 1;
    end
    if (fl_in.free_en1) begin
      v.list = fl_write(v.list, nt[FL_IDX_BITS-1:0], fl_in.free_tag1);
      nt = nt + 1;
      ncc = ncc + 1;
      nsc = nsc + 1;
      nch = nch + 1;
    end

    if (fl_in.alloc0 && nsc >= 1) begin
      nsh = nsh + 1;
      nsc = nsc - 1;
    end
    if (fl_in.alloc1 && nsc >= 2) begin
      nsh = nsh + 1;
      nsc = nsc - 1;
    end

    v.tail            = nt;
    v.spec_count      = nsc;
    v.comm_count      = ncc;
    v.spec_head       = nsh;
    v.comm_head       = nch;

    sh1               = r.spec_head + 1;

    fl_out.alloc_tag0 = fl_read(r.list, r.spec_head[FL_IDX_BITS-1:0]);
    fl_out.alloc_tag1 = fl_read(r.list, sh1[FL_IDX_BITS-1:0]);
    fl_out.alloc_ok0  = r.spec_count >= 1;
    fl_out.alloc_ok1  = r.spec_count >= 2;
    fl_out.empty      = (r.spec_count == 0);
    fl_out.has_two    = r.spec_count >= 2;

    rin               = v;

  end

  always_ff @(posedge clock) begin
    if (reset == 0) begin
      fl_reg_type init_v;
      integer k;
      init_v.list       = '0;
      init_v.spec_head  = '0;
      init_v.comm_head  = '0;
      init_v.tail       = FL_CNT_BITS'(FLIST_DEPTH);
      init_v.spec_count = FL_CNT_BITS'(FLIST_DEPTH);
      init_v.comm_count = FL_CNT_BITS'(FLIST_DEPTH);
      for (k = 0; k < FLIST_DEPTH; k++)
      init_v.list[k*PRF_ADDR_BITS+:PRF_ADDR_BITS] = PRF_ADDR_BITS'(ARCH_REGS + k);
      r <= init_v;
    end else if (flush) begin
      begin : rebuild
        integer i;
        logic [FL_IDX_BITS-1:0] src_pos;
        logic [FL_CNT_BITS-1:0] start;
        start = rin.tail - rin.comm_count;
        for (i = 0; i < FLIST_DEPTH; i++) begin
          src_pos = start[FL_IDX_BITS-1:0] + FL_IDX_BITS'(unsigned'(i));
          r.list[i*PRF_ADDR_BITS+:PRF_ADDR_BITS] <= rin.list[src_pos*PRF_ADDR_BITS+:PRF_ADDR_BITS];
        end
      end
      r.spec_head  <= '0;
      r.comm_head  <= '0;
      r.tail       <= rin.comm_count;
      r.spec_count <= rin.comm_count;
      r.comm_count <= rin.comm_count;
    end else begin
      r <= rin;
    end
  end

endmodule
