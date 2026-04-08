#!/bin/bash
set -e

start=`date +%s`

${VERIBLE}-verilog-format --inplace \
            ${BASEDIR}/verilog/conf/configure.sv \
            ${BASEDIR}/verilog/rtl/constants.sv \
            ${BASEDIR}/verilog/rtl/wires.sv \
            ${BASEDIR}/verilog/rtl/functions.sv \
            ${BASEDIR}/verilog/rtl/bit_alu.sv \
            ${BASEDIR}/verilog/rtl/bit_clmul.sv \
            ${BASEDIR}/verilog/rtl/btac.sv \
            ${BASEDIR}/verilog/rtl/alu.sv \
            ${BASEDIR}/verilog/rtl/agu.sv \
            ${BASEDIR}/verilog/rtl/bcu.sv \
            ${BASEDIR}/verilog/rtl/lsu.sv \
            ${BASEDIR}/verilog/rtl/csr_alu.sv \
            ${BASEDIR}/verilog/rtl/mul.sv \
            ${BASEDIR}/verilog/rtl/div.sv \
            ${BASEDIR}/verilog/rtl/compress.sv \
            ${BASEDIR}/verilog/rtl/decoder.sv \
            ${BASEDIR}/verilog/rtl/register.sv \
            ${BASEDIR}/verilog/rtl/csr.sv \
            ${BASEDIR}/verilog/rtl/buffer.sv \
            ${BASEDIR}/verilog/rtl/ifetch.sv \
            ${BASEDIR}/verilog/rtl/idecode.sv \
            ${BASEDIR}/verilog/rtl/arbiter.sv \
            ${BASEDIR}/verilog/rtl/bridge.sv \
            ${BASEDIR}/verilog/rtl/bus.sv \
            ${BASEDIR}/verilog/rtl/cdc.sv \
            ${BASEDIR}/verilog/rtl/clint.sv \
            ${BASEDIR}/verilog/rtl/tim.sv \
            ${BASEDIR}/verilog/rtl/rom.sv \
            ${BASEDIR}/verilog/rtl/ram.sv \
            ${BASEDIR}/verilog/rtl/spi.sv \
            ${BASEDIR}/verilog/rtl/uart_rx.sv \
            ${BASEDIR}/verilog/rtl/uart_tx.sv \
            ${BASEDIR}/verilog/rtl/prf.sv \
            ${BASEDIR}/verilog/rtl/free_list.sv \
            ${BASEDIR}/verilog/rtl/rat.sv \
            ${BASEDIR}/verilog/rtl/rob.sv \
            ${BASEDIR}/verilog/rtl/rs_int.sv \
            ${BASEDIR}/verilog/rtl/rs_mem.sv \
            ${BASEDIR}/verilog/rtl/rename.sv \
            ${BASEDIR}/verilog/rtl/eu.sv \
            ${BASEDIR}/verilog/rtl/ldu.sv \
            ${BASEDIR}/verilog/rtl/commit.sv \
            ${BASEDIR}/verilog/rtl/cpu.sv \
            ${BASEDIR}/verilog/rtl/soc.sv \
            ${BASEDIR}/verilog/tb/testbench.sv

end=`date +%s`
echo Execution time was `expr $end - $start` seconds.