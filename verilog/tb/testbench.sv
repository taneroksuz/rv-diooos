import configure::*;
import wires::*;

module testbench ();
  timeunit 1ns; timeprecision 1ps;

  logic reset;
  logic clock;
  logic sclk;
  logic mosi;
  logic miso = 1'b1;
  logic ss;
  logic rx = 1'b1;
  logic tx;
  logic [1:0] clear;

  mem_in_type ram_in;
  mem_out_type ram_out;

  logic [31:0] host[0:0];
  logic [31:0] stoptime = 10000000;
  logic [31:0] counter = 0;

  integer reg_file;
  integer csr_file;
  integer mem_file;

  initial begin
    $readmemh("host.dat", host);
  end

  initial begin
    string filename;
    if ($value$plusargs("FILENAME=%s", filename)) begin
      $dumpfile(filename);
      $dumpvars(0, testbench);
    end
  end

  initial begin
    string maxtime;
    if ($value$plusargs("MAXTIME=%s", maxtime)) begin
      stoptime = maxtime.atoi();
    end
  end

  initial begin
    reset = 0;
    clock = 1;
  end

  initial begin
    #10 reset = 1;
  end

  always #0.5 clock = ~clock;

  always_ff @(posedge clock) begin
    if (reset == 0) begin
      clear <= 2'b11;
    end else begin
      clear <= {1'b0, clear[1]};
    end
  end

  always_ff @(posedge clock) begin
    if (counter == stoptime) begin
      $finish;
    end else begin
      counter <= counter + 1;
    end
  end

  wire        commit0_valid = testbench.soc_comp.cpu_comp.rob_out.commit0;
  wire        commit1_valid = testbench.soc_comp.cpu_comp.rob_out.commit1;
  wire [31:0] commit0_pc = testbench.soc_comp.cpu_comp.rob_out.entry0.pc;
  wire [31:0] commit1_pc = testbench.soc_comp.cpu_comp.rob_out.entry1.pc;
  wire [ 4:0] commit0_waddr = testbench.soc_comp.cpu_comp.rob_out.entry0.adest;
  wire [ 4:0] commit1_waddr = testbench.soc_comp.cpu_comp.rob_out.entry1.adest;
  wire [31:0] commit0_wdata = testbench.soc_comp.cpu_comp.rob_out.entry0.result;
  wire [31:0] commit1_wdata = testbench.soc_comp.cpu_comp.rob_out.entry1.result;
  wire        commit0_wren = testbench.soc_comp.cpu_comp.rob_out.entry0.wren;
  wire        commit1_wren = testbench.soc_comp.cpu_comp.rob_out.entry1.wren;
  wire        commit0_store = testbench.soc_comp.cpu_comp.rob_out.entry0.store;
  wire [31:0] commit0_saddr = testbench.soc_comp.cpu_comp.rob_out.entry0.store_addr;
  wire [31:0] commit0_sdata = testbench.soc_comp.cpu_comp.rob_out.entry0.store_data;
  wire [ 3:0] commit0_sstrb = testbench.soc_comp.cpu_comp.rob_out.entry0.store_strb;
  wire        commit0_cwren = testbench.soc_comp.cpu_comp.rob_out.entry0.cwren;
  wire [11:0] commit0_caddr = testbench.soc_comp.cpu_comp.rob_out.entry0.caddr;
  wire [31:0] commit0_cwdata = testbench.soc_comp.cpu_comp.rob_out.entry0.cwdata;

  initial begin
    string filename;
    if ($value$plusargs("REGFILE=%s", filename)) begin
      reg_file = $fopen(filename, "w");
      for (int i = 0; i < stoptime; i = i + 1) begin
        @(posedge clock);
        if (commit0_valid && commit0_wren) begin
          $fwrite(reg_file, "PERIOD = %t\t", $time);
          $fwrite(reg_file, "PC = %x\t", commit0_pc);
          $fwrite(reg_file, "WADDR = %x\t", commit0_waddr);
          $fwrite(reg_file, "WDATA = %x\n", commit0_wdata);
        end
        if (commit1_valid && commit1_wren) begin
          $fwrite(reg_file, "PERIOD = %t\t", $time);
          $fwrite(reg_file, "PC = %x\t", commit1_pc);
          $fwrite(reg_file, "WADDR = %x\t", commit1_waddr);
          $fwrite(reg_file, "WDATA = %x\n", commit1_wdata);
        end
      end
      $fclose(reg_file);
    end
  end

  initial begin
    string filename;
    if ($value$plusargs("CSRFILE=%s", filename)) begin
      csr_file = $fopen(filename, "w");
      for (int i = 0; i < stoptime; i = i + 1) begin
        @(posedge clock);
        if (commit0_valid && commit0_cwren) begin
          $fwrite(csr_file, "PERIOD = %t\t", $time);
          $fwrite(csr_file, "PC = %x\t", commit0_pc);
          $fwrite(csr_file, "WADDR = %x\t", commit0_caddr);
          $fwrite(csr_file, "WDATA = %x\n", commit0_cwdata);
        end
      end
      $fclose(csr_file);
    end
  end

  initial begin
    string filename;
    if ($value$plusargs("MEMFILE=%s", filename)) begin
      mem_file = $fopen(filename, "w");
      for (int i = 0; i < stoptime; i = i + 1) begin
        @(posedge clock);
        if (commit0_valid && commit0_store && |commit0_sstrb) begin
          $fwrite(mem_file, "PERIOD = %t\t", $time);
          $fwrite(mem_file, "PC = %x\t", commit0_pc);
          $fwrite(mem_file, "WADDR = %x\t", commit0_saddr);
          $fwrite(mem_file, "WSTRB = %b\t", commit0_sstrb);
          $fwrite(mem_file, "WDATA = %x\n", commit0_sdata);
        end
      end
      $fclose(mem_file);
    end
  end

  always_ff @(posedge clock) begin
    if (commit0_valid && commit0_store && |commit0_sstrb) begin
      if (commit0_saddr[31:3] == host[0][31:3]) begin
        $display("%d", commit0_sdata[31:0]);
        $finish;
      end
    end
  end

  soc soc_comp (
      .reset(reset),
      .clear(clear[0]),
      .clock(clock),
      .sclk(sclk),
      .mosi(mosi),
      .miso(miso),
      .ss(ss),
      .rx(rx),
      .tx(tx),
      .ram_in(ram_in),
      .ram_out(ram_out)
  );

  ram ram_comp (
      .reset  (reset),
      .clock  (clock),
      .ram_in (ram_in),
      .ram_out(ram_out)
  );

endmodule
