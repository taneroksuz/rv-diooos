package buffer_wires;
  timeunit 1ns; timeprecision 1ps;

  import configure::*;

  localparam DEPTH = $clog2(BUFFER_DEPTH);

  typedef struct packed {
    logic [3:0][0 : 0] wen;
    logic [3:0][DEPTH-1 : 0] waddr;
    logic [3:0][DEPTH-1 : 0] raddr;
    logic [3:0][47 : 0] wdata;
  } buffer_reg_in_type;

  typedef struct packed {logic [3:0][47 : 0] rdata;} buffer_reg_out_type;

endpackage

import configure::*;
import constants::*;
import wires::*;
import buffer_wires::*;

module buffer_reg (
  input  logic               clock,
  input  buffer_reg_in_type  buffer_reg_in,
  output buffer_reg_out_type buffer_reg_out
);
  timeunit 1ns; timeprecision 1ps;

  localparam DEPTH = $clog2(BUFFER_DEPTH);

  generate
    for (genvar i = 0; i < 4; i++) begin : gen_buffer_reg_array
      logic [47:0] buffer_reg_array[0:BUFFER_DEPTH-1] = '{default: '0};
      always_ff @(posedge clock) begin
        if (buffer_reg_in.wen[i] == 1) begin
          buffer_reg_array[buffer_reg_in.waddr[i]] <= buffer_reg_in.wdata[i];
        end
      end
      always_comb begin
        buffer_reg_out.rdata[i] = buffer_reg_in.raddr[i] == buffer_reg_in.waddr[i] ? buffer_reg_in.wdata[i] : buffer_reg_array[buffer_reg_in.raddr[i]];
      end
    end
  endgenerate

endmodule

module buffer_ctrl (
  input  logic               reset,
  input  logic               clock,
  input  buffer_in_type      buffer_in,
  output buffer_out_type     buffer_out,
  input  buffer_reg_out_type buffer_reg_out,
  output buffer_reg_in_type  buffer_reg_in
);
  timeunit 1ns; timeprecision 1ps;

  localparam DEPTH = $clog2(BUFFER_DEPTH);
  localparam TOTAL = 4 * (BUFFER_DEPTH - 2);

  localparam [DEPTH-1:0] one = 1;

  typedef struct packed {
    logic [DEPTH+1 : 0] wid;
    logic [DEPTH+1 : 0] rid;
    logic [DEPTH+1 : 0] diff;
    logic [DEPTH+1 : 0] count;
    logic [DEPTH+1 : 0] align;
    logic [3:0][47 : 0] wdata;
    logic [3:0][47 : 0] rdata;
    logic [1:0][31 : 0] pc;
    logic [1:0][31 : 0] instr;
    logic [3 : 0] comp;
    logic [3 : 0] ready;
    logic [0 : 0] wen;
    logic [0 : 0] clear;
    logic [0 : 0] stall;
  } reg_type;

  parameter reg_type init_reg = '{
      wid : 0,
      rid : 0,
      diff : 0,
      count : 0,
      align : 0,
      wdata : '{default: '0},
      rdata : '{default: '0},
      pc : '{default: '0},
      instr : '{default: '0},
      comp : 0,
      ready : 0,
      wen : 0,
      clear : 0,
      stall : 0
  };

  reg_type r, rin, v;

  function automatic int slot_offset(input logic [3:0] comp, input int slot);
    int off;
    off = 0;
    off += (slot > 0) ? (comp[0] ? 1 : 2) : 0;
    return off;
  endfunction

  int base, need;

  always_comb begin

    v = r;

    if (buffer_in.clear == 1) begin
      v.wid   = 0;
      v.rid   = 0;
      v.count = 0;
      v.clear = 1;
    end

    if (r.clear == 1 && buffer_in.clear == 0 && buffer_in.ready == 1) begin
      v.rid   = {{DEPTH + 1{1'b0}}, buffer_in.pc0[1]};
      v.align = {{DEPTH + 1{1'b0}}, buffer_in.pc0[1]};
      v.clear = 0;
    end

    v.wen                  = (~buffer_in.clear) & (~r.stall) & buffer_in.ready;

    v.wdata[0]             = {buffer_in.pc0[31:2], 2'b00, buffer_in.rdata[15:0]};
    v.wdata[1]             = {buffer_in.pc0[31:2], 2'b10, buffer_in.rdata[31:16]};
    v.wdata[2]             = {buffer_in.pc1[31:2], 2'b00, buffer_in.rdata[47:32]};
    v.wdata[3]             = {buffer_in.pc1[31:2], 2'b10, buffer_in.rdata[63:48]};

    buffer_reg_in.wen[0]   = v.wen;
    buffer_reg_in.wen[1]   = v.wen;
    buffer_reg_in.wen[2]   = v.wen;
    buffer_reg_in.wen[3]   = v.wen;
    buffer_reg_in.waddr[0] = v.wid[DEPTH+1:2];
    buffer_reg_in.waddr[1] = v.wid[DEPTH+1:2];
    buffer_reg_in.waddr[2] = v.wid[DEPTH+1:2];
    buffer_reg_in.waddr[3] = v.wid[DEPTH+1:2];
    buffer_reg_in.wdata[0] = v.wdata[0];
    buffer_reg_in.wdata[1] = v.wdata[1];
    buffer_reg_in.wdata[2] = v.wdata[2];
    buffer_reg_in.wdata[3] = v.wdata[3];

    if (v.rid[1:0] == 0) begin
      buffer_reg_in.raddr[0] = v.rid[DEPTH+1:2];
      buffer_reg_in.raddr[1] = v.rid[DEPTH+1:2];
      buffer_reg_in.raddr[2] = v.rid[DEPTH+1:2];
      buffer_reg_in.raddr[3] = v.rid[DEPTH+1:2];
    end else if (v.rid[1:0] == 1) begin
      buffer_reg_in.raddr[0] = v.rid[DEPTH+1:2] + one;
      buffer_reg_in.raddr[1] = v.rid[DEPTH+1:2];
      buffer_reg_in.raddr[2] = v.rid[DEPTH+1:2];
      buffer_reg_in.raddr[3] = v.rid[DEPTH+1:2];
    end else if (v.rid[1:0] == 2) begin
      buffer_reg_in.raddr[0] = v.rid[DEPTH+1:2] + one;
      buffer_reg_in.raddr[1] = v.rid[DEPTH+1:2] + one;
      buffer_reg_in.raddr[2] = v.rid[DEPTH+1:2];
      buffer_reg_in.raddr[3] = v.rid[DEPTH+1:2];
    end else begin
      buffer_reg_in.raddr[0] = v.rid[DEPTH+1:2] + one;
      buffer_reg_in.raddr[1] = v.rid[DEPTH+1:2] + one;
      buffer_reg_in.raddr[2] = v.rid[DEPTH+1:2] + one;
      buffer_reg_in.raddr[3] = v.rid[DEPTH+1:2];
    end

    if (v.rid[1:0] == 0) begin
      v.rdata[0] = buffer_reg_out.rdata[0];
      v.rdata[1] = buffer_reg_out.rdata[1];
      v.rdata[2] = buffer_reg_out.rdata[2];
      v.rdata[3] = buffer_reg_out.rdata[3];
    end else if (v.rid[1:0] == 1) begin
      v.rdata[0] = buffer_reg_out.rdata[1];
      v.rdata[1] = buffer_reg_out.rdata[2];
      v.rdata[2] = buffer_reg_out.rdata[3];
      v.rdata[3] = buffer_reg_out.rdata[0];
    end else if (v.rid[1:0] == 2) begin
      v.rdata[0] = buffer_reg_out.rdata[2];
      v.rdata[1] = buffer_reg_out.rdata[3];
      v.rdata[2] = buffer_reg_out.rdata[0];
      v.rdata[3] = buffer_reg_out.rdata[1];
    end else begin
      v.rdata[0] = buffer_reg_out.rdata[3];
      v.rdata[1] = buffer_reg_out.rdata[0];
      v.rdata[2] = buffer_reg_out.rdata[1];
      v.rdata[3] = buffer_reg_out.rdata[2];
    end

    if (v.wen == 1) begin
      v.wid   = v.wid + 4;
      v.count = v.count + 4;
    end

    v.diff    = 0;

    v.comp[0] = ~(&v.rdata[0][1:0]);
    v.comp[1] = ~(&v.rdata[1][1:0]);
    v.comp[2] = ~(&v.rdata[2][1:0]);
    v.comp[3] = ~(&v.rdata[3][1:0]);

    for (int s = 0; s < 2; s++) begin
      v.pc[s]    = '0;
      v.instr[s] = '0;
      v.ready[s] = 0;
    end

    for (int s = 0; s < 2; s++) begin
      base = slot_offset(v.comp, s);
      need = v.comp[base] ? 1 : 2;
      if (v.count > v.align + 4'(base) + (v.comp[base] ? 4'b0 : 4'b1)) begin
        v.pc[s] = v.rdata[base][47:16];
        if (v.comp[base]) begin
          v.instr[s] = {16'b0, v.rdata[base][15:0]};
        end else begin
          v.instr[s] = {v.rdata[base+1][15:0], v.rdata[base][15:0]};
        end
        v.ready[s] = 1;
        v.diff     = 4'(base) + 4'(need);
      end
    end

    if (buffer_in.stall == 1) begin
      v.diff  = 0;
      v.ready = '0;
    end

    v.count = v.count - v.diff;
    v.rid   = v.rid + v.diff;

    if (v.count > TOTAL) begin
      v.stall = 1;
    end else begin
      v.stall = 0;
    end

    buffer_out.pc0    = v.ready[0] ? v.pc[0] : 32'hFFFFFFFF;
    buffer_out.pc1    = v.ready[1] ? v.pc[1] : 32'hFFFFFFFF;
    buffer_out.instr0 = v.ready[0] ? v.instr[0] : 0;
    buffer_out.instr1 = v.ready[1] ? v.instr[1] : 0;
    buffer_out.ready0 = v.ready[0];
    buffer_out.ready1 = v.ready[1];
    buffer_out.stall  = ~v.wen;

    rin               = v;

  end

  always_ff @(posedge clock) begin
    if (reset == 0) begin
      r <= init_reg;
    end else begin
      r <= rin;
    end
  end

endmodule

module buffer (
  input  logic           reset,
  input  logic           clock,
  input  buffer_in_type  buffer_in,
  output buffer_out_type buffer_out
);
  timeunit 1ns; timeprecision 1ps;

  buffer_reg_in_type  buffer_reg_in;
  buffer_reg_out_type buffer_reg_out;

  buffer_reg buffer_reg_comp (
    .clock         (clock),
    .buffer_reg_in (buffer_reg_in),
    .buffer_reg_out(buffer_reg_out)
  );

  buffer_ctrl buffer_ctrl_comp (
    .reset         (reset),
    .clock         (clock),
    .buffer_in     (buffer_in),
    .buffer_out    (buffer_out),
    .buffer_reg_in (buffer_reg_in),
    .buffer_reg_out(buffer_reg_out)
  );

endmodule
